//
//  BusinessReview.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class BusinessReview: IBusinessReview {
    var username: String
    var timeCreated: Date
    var text: String
    
    init(username: String, timeCreated: Date, text: String) {
        self.username = username
        self.timeCreated = timeCreated
        self.text = text
    }
}
