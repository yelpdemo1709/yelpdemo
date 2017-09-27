//
//  RestaurantFactory.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-27.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class RestaurantFactory: IRestaurantFactory {
    func createRestaurant(id: String, name: String, address: String) -> IRestaurant {
        return Restaurant(id: id, name: name, address: address)
    }
}
