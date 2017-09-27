//
//  YelpRestaurantFinder.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit
import Alamofire

class YelpRestaurantFinder: NSObject {
    
    var restaurantFactory: IRestaurantFactory?
    var businessReviewFactory: IBusinessReviewFactory?
    
    static let YelpClientId = "FI4jT38JN3e-37WNN1g3DA"
    static let YelpClientSecret = "grVbycNeX6sNWdvCe9ZTmmDYb87RZ0TlZldRghndJsSnqmzbPjsGse1etjzvIyEF"
    static let YelpApiTokenUri = "https://api.yelp.com/oauth2/token"
    var token: YelpToken?
    
    static let YelpApiSearchUri = "https://api.yelp.com/v3/businesses/search"
    static let YelpApiSearchLocation = "Toronto, ON"
    
    static let YelpApiReviewUri = "https://api.yelp.com/v3/businesses/{id}/reviews"

    static let kYelpTokenErrorDomain = "kYelpTokenErrorDomain"
    enum TokenRefreshErrorCode: Int {
        case InvalidResponse = 1000, MissingRequiredInfo
    }
    
    static let kYelpSearchErrorDomain = "kYelpSearchErrorDomain"
    enum SearchErrorCode: Int {
        case MissingToken = 1000, InvalidResponse, MissingRequiredInfo, FactoryNotExist
    }
    
    static let kYelpReviewErrorDomain = "kYelpReviewErrorDomain"
    enum ReviewErrorCode: Int {
        case MissingToken = 1000, InvalidResponse, MissingRequiredInfo, FactoryNotExist
    }

    static let sharedInstance = YelpRestaurantFinder()

    func refreshTokenAsNeeded(then: @escaping (NSError?) -> Void) {
        var refreshNeeded = true
        if let cachedToken = token {
            if cachedToken.expiration <= Date() {
                print("Cached Yelp token expired")
                token = nil
            } else {
                refreshNeeded = false
                then(nil)
            }
        } else {
            print("No cached Yelp token")
        }
        if refreshNeeded {
            let parameters: Parameters = [
                "grant_type": "client_credentials",
                "client_id": YelpRestaurantFinder.YelpClientId,
                "client_secret": YelpRestaurantFinder.YelpClientSecret
            ]
            Alamofire.request(YelpRestaurantFinder.YelpApiTokenUri,
                              method: .post,
                              parameters: parameters).responseJSON { response in
                self.logResponse(response)
                if let json = response.result.value as? [String: Any] {
                    if let token = json["access_token"] as? String, let interval = json["expires_in"] as? TimeInterval {
                        self.token = YelpToken(token: token, expires: Date(timeIntervalSinceNow:interval))
                        then(nil)
                    } else {
                        let e = self.errorFromTokenRefresh(code: .MissingRequiredInfo, underlyingError: response.error)
                        print(e.localizedDescription)
                        then(e)
                    }
                } else {
                    let e = self.errorFromTokenRefresh(code: .InvalidResponse, underlyingError: response.error)
                    print(e.localizedDescription)
                    then(e)
                }
            }
        }
    }

    func queryRestaurants(keyword: String?, completion: @escaping (_ restaurant: [IRestaurant]?, _ error: NSError?) -> Void) {
        refreshTokenAsNeeded { (error) in
            if error != nil {
                completion(nil, error)
            } else {
                guard let tkn = self.token else {
                    let e = self.errorFromSearch(code: .MissingToken, underlyingError: nil)
                    print(e.localizedDescription)
                    completion(nil, e)
                    return
                }
                var parameters: Parameters = [
                    "categories": "restaurants, All",
                    "location": YelpRestaurantFinder.YelpApiSearchLocation,
                    "limit": "50"
                ]
                if let key = keyword {
                    if !key.isEmpty {
                        parameters["term"] = key
                        parameters["limit"] = "10"
                    }
                }
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer " + tkn.tokenStr
                ]
                Alamofire.request(YelpRestaurantFinder.YelpApiSearchUri,
                                  method: .get,
                                  parameters: parameters,
                                  encoding: URLEncoding.default,
                                  headers: headers).responseJSON { response in
                    self.logResponse(response)
                    if let json = response.result.value as? [String: Any] {
                        if let businesses = json["businesses"] as? Array<Dictionary<String, Any>> {
                            if let factory = self.restaurantFactory {
                                var restaurants = [IRestaurant]()
                                for business in businesses {
                                    if let id = business["id"] as? String,
                                        let name = business["name"] as? String,
                                        let location = business["location"] as? Dictionary<String, Any>,
                                        let addressArray = location["display_address"] as? Array<String> {
                                        if addressArray.count > 0 {
                                            let address = addressArray.joined(separator: ", ")
                                            var restaurant = factory.createRestaurant(id: id, name: name, address: address)
                                            if let imageUrlStr = business["image_url"] as? String {
                                                restaurant.imageUrlStr = imageUrlStr
                                            }
                                            restaurants.append(restaurant)
                                        }
                                    } else {
                                        print("Unexpected format")
                                    }
                                }
                                completion(restaurants, nil)
                            } else {
                                let e = self.errorFromSearch(code: .FactoryNotExist, underlyingError: nil)
                                print(e.localizedDescription)
                                completion(nil, e)
                            }
                        } else {
                            let e = self.errorFromSearch(code: .MissingRequiredInfo, underlyingError: response.error)
                            print(e.localizedDescription)
                            completion(nil, e)
                        }
                    } else {
                        let e = self.errorFromSearch(code: .InvalidResponse, underlyingError: response.error)
                        print(e.localizedDescription)
                        completion(nil, e)
                    }
                }
            }
        }
    }
    
    func queryRestaurantReview(restaurant: IRestaurant, completion: @escaping (_ reviews: [IBusinessReview]?, _ error: NSError?) -> Void) {
        refreshTokenAsNeeded { (error) in
            if error != nil {
                completion(nil, error)
            } else {
                guard let tkn = self.token else {
                    let e = self.errorFromReview(code: .MissingToken, underlyingError: nil)
                    print(e.localizedDescription)
                    completion(nil, e)
                    return
                }
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer " + tkn.tokenStr
                ]
                let originalId = restaurant.id
                let escapedId = originalId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                let requestUrlStr = YelpRestaurantFinder.YelpApiReviewUri.replacingOccurrences(of: "{id}", with: escapedId ?? originalId)
                Alamofire.request(requestUrlStr,
                                  method: .get,
                                  parameters: nil,
                                  encoding: URLEncoding.default,
                                  headers: headers).responseJSON { response in
                                    self.logResponse(response)
                                    if let json = response.result.value as? [String: Any] {
                                        if let reviewsArray = json["reviews"] as? Array<Dictionary<String, Any>> {
                                            if let factory = self.businessReviewFactory {
                                                var reviews = [IBusinessReview]()
                                                for reviewDict in reviewsArray {
                                                    if let text = reviewDict["text"] as? String,
                                                        let user = reviewDict["user"] as? Dictionary<String, Any>,
                                                        let username = user["name"] as? String,
                                                        let dateStr = reviewDict["time_created"] as? String {
                                                        let dateFormatter = DateFormatter()
                                                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                                        if let date = dateFormatter.date(from: dateStr) {
                                                            let review = factory.createBusinessReview(username: username, timeCreated: date, text: text)
                                                            reviews.append(review)
                                                        } else {
                                                            print("Unexpected format")
                                                        }
                                                    } else {
                                                        print("Unexpected format")
                                                    }
                                                }
                                                completion(reviews, nil)
                                            } else {
                                                let e = self.errorFromReview(code: .FactoryNotExist, underlyingError: nil)
                                                print(e.localizedDescription)
                                                completion(nil, e)
                                            }
                                        } else {
                                            let e = self.errorFromReview(code: .MissingRequiredInfo, underlyingError: response.error)
                                            print(e.localizedDescription)
                                            completion(nil, e)
                                        }
                                    } else {
                                        let e = self.errorFromReview(code: .InvalidResponse, underlyingError: response.error)
                                        print(e.localizedDescription)
                                        completion(nil, e)
                                    }
                }
            }
        }
    }
    
    func logResponse(_ response: DataResponse<Any>) {
        print("Request: \(String(describing: response.request))")
        print("Response: \(String(describing: response.response))")
        print("Error: \(String(describing: response.error))")
    }
    
    func errorFromTokenRefresh(code: TokenRefreshErrorCode, underlyingError: Error?) -> NSError {
        var errMsg: String?
        switch code {
        case .InvalidResponse:
            errMsg = "Invalid response"
        case .MissingRequiredInfo:
            errMsg = "Response doesn't contain required info"
        }
        var userInfo = [String: Any]()
        if let msg = errMsg {
            userInfo[NSLocalizedDescriptionKey] = msg
        }
        if let alamofireError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = alamofireError
        }
        return NSError(domain: YelpRestaurantFinder.kYelpTokenErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    func errorFromSearch(code: SearchErrorCode, underlyingError: Error?) -> NSError {
        var errMsg: String?
        switch code {
        case .MissingToken:
            errMsg = "Missing token"
        case .InvalidResponse:
            errMsg = "Invalid response"
        case .MissingRequiredInfo:
            errMsg = "Response doesn't contain required info"
        case .FactoryNotExist:
            errMsg = "Factory doesn't exist"
        }
        var userInfo = [String: Any]()
        if let msg = errMsg {
            userInfo[NSLocalizedDescriptionKey] = msg
        }
        if let alamofireError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = alamofireError
        }
        return NSError(domain: YelpRestaurantFinder.kYelpSearchErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    func errorFromReview(code: ReviewErrorCode, underlyingError: Error?) -> NSError {
        var errMsg: String?
        switch code {
        case .MissingToken:
            errMsg = "Missing token"
        case .InvalidResponse:
            errMsg = "Invalid response"
        case .MissingRequiredInfo:
            errMsg = "Response doesn't contain required info"
        case .FactoryNotExist:
            errMsg = "Factory doesn't exist"
        }
        var userInfo = [String: Any]()
        if let msg = errMsg {
            userInfo[NSLocalizedDescriptionKey] = msg
        }
        if let alamofireError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = alamofireError
        }
        return NSError(domain: YelpRestaurantFinder.kYelpReviewErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}
