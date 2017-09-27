//
//  IRestaurant.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

protocol IRestaurant {
    var id: String { get }
    var name: String { get }
    var address: String { get }
    var imageUrlStr: String? { get set }
}
