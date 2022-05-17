//
//  SpotFromCloud.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import Foundation
import CloudKit
import UIKit

struct SpotFromCloud: Hashable, Identifiable {
    let id: String
    let name: String
    let founder: String
    let description: String
    let date: String
    let location: CLLocation
    let type: String
    let imageURL: URL
    var image2URL: UIImage?
    var image3URL: UIImage?
    let isMultipleImages: Int
    var likes: Int
    var offensive: Int
    var spam: Int
    var inappropriate: Int
    var dangerous: Int
    let customLocation: Int
    let locationName: String
    let userID: String
    let dateObject: Date?
    let record: CKRecord
}
