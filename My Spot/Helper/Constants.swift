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
    static let names = 20
    static let emojis = 1
    static let description = 1200
    static let bio = 100
    static let fullName = 30
    static let email = 320
}

// defines user default keys
enum UserDefaultKeys {
    static let founder = "Founder"
    static let isFilterByLocation = "isFilterByLocation"
    static let lastKnownUserLocationX = "lastKnownUserLocationX"
    static let lastKnownUserLocationY = "lastKnownUserLocationY"
}

// image protection
enum defaultImages {
    static let errorImage = UIImage(systemName: "exclamationmark.triangle")
}

enum Account {
    static let name = "accountname"
    static let pronouns = "accountpronouns"
    static let email = "accountemail"
    static let bio = "accountbio"
    static let isExplorer = "accountexplorer"
    static let downloads = "accountdownloads"
    static let totalSpots = "accounttotalspots"
    static let image = "accountimage"
    static let tiktok = "accounttiktok"
    static let youtube = "accountyoutube"
    static let insta = "accountinstagram"
    static let membersince = "accountcreation"
}


