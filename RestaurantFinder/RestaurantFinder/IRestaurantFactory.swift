//
//  IRestaurantFactory.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

protocol IRestaurantFactory {
    func createRestaurant(id: String, name: String, address: String) -> IRestaurant;
}
