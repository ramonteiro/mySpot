//
//  Constants.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/24/22.
//

/*
 keeps code typesafe
 also allows for quick changes across code
 */

import Foundation

enum MaxCharLength {
    static let names = 20
    static let emojis = 1
    static let description = 1200
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
    static let maxLoadPerFetch = 4
    static let maxLoadTotal = 20
}
