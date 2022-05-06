//
//  SpotModel.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import Foundation

struct Spot: Identifiable, Codable, Hashable {
    var id = UUID()
    let spotid: String
    let name: String
    let customLocation: Bool
    let locationName: String
    let image: Data
    let x: Double
    let y: Double
}
