//
//  YelpRestaurantFinder.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

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

    static let YelpApiBusinessesUri = "https://api.yelp.com/v3/businesses/{id}"
    
    enum YelpFinderErrorDomain: String {
        case kYelpTokenErrorDomain = "kYelpTokenErrorDomain"
        case kYelpSearchErrorDomain = "kYelpSearchErrorDomain"
        case kYelpReviewErrorDomain = "kYelpReviewErrorDomain"
        case kYelpBusinessesErrorDomain = "kYelpBusinessesErrorDomain"
    }

    enum YelpFinderErrorCode: Int {
        case MissingToken = 1000, InvalidResponse, MissingRequiredInfo, FactoryNotExist
    }

    static let sharedInstance = YelpRestaurantFinder()

    func refreshTokenAsNeeded(then: @escaping (NSError?) -> Void) {
        if token != nil && token!.isValid() {
            then(nil)
        } else {
            print("No cached Yelp token or it expired")
            token = nil
            let parameters: Parameters = [
                "grant_type": "client_credentials",
                "client_id": YelpRestaurantFinder.YelpClientId,
                "client_secret": YelpRestaurantFinder.YelpClientSecret
            ]
            Alamofire.request(YelpRestaurantFinder.YelpApiTokenUri,
                              method: .post,
                              parameters: parameters).responseJSON { response in
                                self.logResponse(response)
                                switch response.result {
                                case .success(let value):
                                    let json = JSON(value)
                                    print("JSON: \(json)")
                                    if let token = json["access_token"].string, let interval = json["expires_in"].double {
                                        self.token = YelpToken(token: token, expires: Date(timeIntervalSinceNow:interval))
                                        then(nil)
                                    } else {
                                        let e = self.errorFrom(domain: .kYelpTokenErrorDomain, code: .MissingRequiredInfo, underlyingError: response.error)
                                        print(e.localizedDescription)
                                        then(e)
                                    }
                                case .failure(let error):
                                    print(error)
                                    let e = self.errorFrom(domain: .kYelpTokenErrorDomain, code: .InvalidResponse, underlyingError: response.error)
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
                    let e = self.errorFrom(domain: .kYelpSearchErrorDomain, code: .MissingToken, underlyingError: nil)
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
                    switch response.result {
                    case .success(let value):
                        let json = JSON(value)
                        print("JSON: \(json)")
                        if let businesses = json["businesses"].array {
                            if let factory = self.restaurantFactory {
                                var restaurants = [IRestaurant]()
                                for business in businesses {
                                    if let id = business["id"].string,
                                        let name = business["name"].string,
                                        let addressArray = business["location"]["display_address"].array {
                                        if addressArray.count > 0 {
                                            let address = addressArray.map { $0.stringValue}.joined(separator: ", ")
                                            var restaurant = factory.createRestaurant(id: id, name: name, address: address)
                                            restaurant.imageUrlStr = business["image_url"].string
                                            restaurants.append(restaurant)
                                        } else {
                                            print("Unexpected address format")
                                        }
                                    } else {
                                        print("Unexpected format")
                                    }
                                }
                                completion(restaurants, nil)
                            } else {
                                let e = self.errorFrom(domain: .kYelpSearchErrorDomain, code: .FactoryNotExist, underlyingError: nil)
                                print(e.localizedDescription)
                                completion(nil, e)
                            }
                        } else {
                            let e = self.errorFrom(domain: .kYelpSearchErrorDomain, code: .MissingRequiredInfo, underlyingError: response.error)
                            print(e.localizedDescription)
                            completion(nil, e)
                        }
                    case .failure(let error):
                        print(error)
                        let e = self.errorFrom(domain: .kYelpSearchErrorDomain, code: .InvalidResponse, underlyingError: response.error)
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
                    let e = self.errorFrom(domain: .kYelpReviewErrorDomain, code: .MissingToken, underlyingError: nil)
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
                                    switch response.result {
                                    case .success(let value):
                                        let json = JSON(value)
                                        print("JSON: \(json)")
                                        if let reviewsArray = json["reviews"].array {
                                            if let factory = self.businessReviewFactory {
                                                var reviews = [IBusinessReview]()
                                                for reviewDict in reviewsArray {
                                                    if let text = reviewDict["text"].string,
                                                        let username = reviewDict["user"]["name"].string,
                                                        let dateStr = reviewDict["time_created"].string {
                                                        let dateFormatter = DateFormatter()
                                                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                                                        if let date = dateFormatter.date(from: dateStr) {
                                                            let review = factory.createBusinessReview(username: username, timeCreated: date, text: text)
                                                            reviews.append(review)
                                                        } else {
                                                            print("Unexpected date format")
                                                        }
                                                    } else {
                                                        print("Unexpected format")
                                                    }
                                                }
                                                completion(reviews, nil)
                                            } else {
                                                let e = self.errorFrom(domain: .kYelpReviewErrorDomain, code: .FactoryNotExist, underlyingError: nil)
                                                print(e.localizedDescription)
                                                completion(nil, e)
                                            }
                                        } else {
                                            let e = self.errorFrom(domain: .kYelpReviewErrorDomain, code: .MissingRequiredInfo, underlyingError: response.error)
                                            print(e.localizedDescription)
                                            completion(nil, e)
                                        }
                                    case .failure(let error):
                                        print(error)
                                        let e = self.errorFrom(domain: .kYelpReviewErrorDomain, code: .InvalidResponse, underlyingError: response.error)
                                        print(e.localizedDescription)
                                        completion(nil, e)
                                    }
                }
            }
        }
    }
    
    func queryRestaurantPhotos(restaurant: IRestaurant, completion: @escaping (_ reviews: [URL]?, _ error: NSError?) -> Void) {
        refreshTokenAsNeeded { (error) in
            if error != nil {
                completion(nil, error)
            } else {
                guard let tkn = self.token else {
                    let e = self.errorFrom(domain: .kYelpBusinessesErrorDomain, code: .MissingToken, underlyingError: nil)
                    print(e.localizedDescription)
                    completion(nil, e)
                    return
                }
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer " + tkn.tokenStr
                ]
                let originalId = restaurant.id
                let escapedId = originalId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                let requestUrlStr = YelpRestaurantFinder.YelpApiBusinessesUri.replacingOccurrences(of: "{id}", with: escapedId ?? originalId)
                Alamofire.request(requestUrlStr,
                                  method: .get,
                                  parameters: nil,
                                  encoding: URLEncoding.default,
                                  headers: headers).responseJSON { response in
                                    self.logResponse(response)
                                    switch response.result {
                                    case .success(let value):
                                        let json = JSON(value)
                                        print("JSON: \(json)")
                                        if let photosArray = json["photos"].array {
                                            var photos = [URL]()
                                            for photo in photosArray {
                                                if let photoUrl = photo.url {
                                                    photos.append(photoUrl)
                                                } else {
                                                    print("Unexpected format")
                                                }
                                            }
                                            completion(photos, nil)
                                        } else {
                                            let e = self.errorFrom(domain: .kYelpBusinessesErrorDomain, code: .MissingRequiredInfo, underlyingError: response.error)
                                            print(e.localizedDescription)
                                            completion(nil, e)
                                        }
                                    case .failure(let error):
                                        print(error)
                                        let e = self.errorFrom(domain: .kYelpBusinessesErrorDomain, code: .InvalidResponse, underlyingError: response.error)
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
    
    func errorFrom(domain: YelpFinderErrorDomain, code: YelpFinderErrorCode, underlyingError: Error?) -> NSError {
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
        return NSError(domain: domain.rawValue, code: code.rawValue, userInfo: userInfo)
    }
}
