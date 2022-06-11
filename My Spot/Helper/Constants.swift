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
import SwiftUI

// defines max character length for each field
enum MaxCharLength {
    static let names = 30
    static let emojis = 1
    static let description = 1200
    static let bio = 100
    static let fullName = 30
    static let email = 320
}

// defines user default keys
enum UserDefaultKeys {
    static let isFilterByLocation = "isFilterByLocation"
    static let lastKnownUserLocationX = "lastKnownUserLocationX"
    static let lastKnownUserLocationY = "lastKnownUserLocationY"
}

// image protection
enum defaultImages {
    static let errorImage = UIImage(systemName: "exclamationmark.triangle")
}


