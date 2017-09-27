//
//  UIImageViewAsyncExtension.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

private var waitingUrlAssociationKey: UInt8 = 0

extension UIImageView {
    
    var waitingForUrl: String? {
        get {
            return objc_getAssociatedObject(self, &waitingUrlAssociationKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &waitingUrlAssociationKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    public func resetWaitingUrl() {
        waitingForUrl = nil
    }
    
    public func asyncFetchImageFromServerURL(urlString: String, complete:@escaping (Data, Bool) -> Void) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            if let err = error {
                print("\(err)")
                return
            }
            guard let data = data else {
                print("Invalid image data")
                return
            }
            
            // to simulate slow network and reveal UI issues
//            usleep(500000)
            
            DispatchQueue.main.async(execute: { () -> Void in
                if self.waitingForUrl == urlString {
                    print("\(urlString) downloaded")
                    let image = UIImage(data: data)
                    self.image = image
                    complete(data, true)
                } else {
                    print("\(urlString) downloaded but not set, cell is being used for a different program")
                    complete(data, false)
                }
            })
        })
        task.resume()
        waitingForUrl = urlString
        return task
    }
}
