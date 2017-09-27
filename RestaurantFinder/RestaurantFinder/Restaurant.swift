//
//  Restaurant.swift
//  RestaurantFinder
//
//  Created by Matthew Li on 2017-09-26.
//  Copyright © 2017 Matthew Li. All rights reserved.
//

import UIKit

class Restaurant: IRestaurant {
    var id: String
    var name: String
    var address: String
    var imageUrlStr: String?
    
    init(id: String, name: String, address: String) {
        self.id = id
        self.name = name
        self.address = address
    }
}
