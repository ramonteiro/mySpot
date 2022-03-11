//
//  Constants.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/24/22.
//

/*
 keeps code typesafe
 */

import Foundation

enum Constants {
    static let baseURL = "https://myspot-vapor.herokuapp.com/"
}

enum Endpoints {
    static let spots = "spots"
}

enum MaxCharLength {
    static let names = 13
    static let emojis = 1
    static let description = 1200
}

enum Passwords {
    static let delete = "ik"
}

enum UserDefaultKeys {
    static let founder = "Founder"
    static let isFilterByLocation = "isFilterByLocation"
    static let lastKnownUserLocationX = "lastKnownUserLocationX"
    static let lastKnownUserLocationY = "lastKnownUserLocationY"
}

enum LocationForSorting {
    static let locationOff = "location"
    static let locationOn = "location.fill"
}

enum CloudKitConst {
    static let maxLoadPerFetch = 15
    static let maxLoadTotal = 60
}
