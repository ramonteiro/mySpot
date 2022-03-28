//
//  SpotFromCloud.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import Foundation
import CloudKit

struct SpotFromCloud: Hashable, Identifiable {
    let id: String
    let name: String
    let founder: String
    let description: String
    let date: String
    let location: CLLocation
    let type: String
    let imageURL: URL
    let image2URL: URL
    let image3URL: URL
    var likes: Int
    let locationName: String
    let userID: String
    let record: CKRecord
}
