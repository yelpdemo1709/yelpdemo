//
//  YelpToken.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class YelpToken: NSObject {

    var tokenStr: String
    private var expiration: Date
    
    init(token: String, expires: Date) {
        self.tokenStr = token
        self.expiration = expires
    }
    
    func isValid() -> Bool {
        return expiration > Date()
    }
}
