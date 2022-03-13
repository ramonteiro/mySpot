//
//  SpotFromCloud.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import Foundation
import CloudKit

struct SpotFromCloud: Hashable, Identifiable {
    let id: UUID?
    let name: String
    let founder: String
    let description: String
    let date: String
    let location: CLLocation
    let type: String
    let emoji: String
    let imageURL: URL
    var likes: Int
    let record: CKRecord
}
