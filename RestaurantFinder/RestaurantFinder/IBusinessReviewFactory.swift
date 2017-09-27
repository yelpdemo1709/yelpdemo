//
//  IBusinessReviewFactory.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

protocol IBusinessReviewFactory {
    func createBusinessReview(username: String, timeCreated: Date, text: String) -> IBusinessReview;
}
