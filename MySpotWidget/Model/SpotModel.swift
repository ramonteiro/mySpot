//
//  SpotModel.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import Foundation

struct Spot: Identifiable, Codable {
    var id = UUID()
    let spotid: String
    let name: String
    let customLocation: Bool
    let locationName: String
    let image: Data
    let x: Double
    let y: Double
}
