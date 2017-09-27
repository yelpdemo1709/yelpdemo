//
//  IBusinessReview.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

protocol IBusinessReview {
    var username: String { get }
    var timeCreated: Date { get }
    var text: String { get }
}
