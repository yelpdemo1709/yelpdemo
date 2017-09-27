//
//  BusinessReviewFactory.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class BusinessReviewFactory: IBusinessReviewFactory {
    func createBusinessReview(username: String, timeCreated: Date, text: String) -> IBusinessReview {
        return BusinessReview(username: username, timeCreated: timeCreated, text: text)
    }
}
