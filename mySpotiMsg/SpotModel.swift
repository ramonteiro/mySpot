//
//  SpotModel.swift
//  mySpotiMsg
//
//  Created by Isaac Paschall on 6/20/22.
//

import UIKit

struct msgSpot: Identifiable {
    let id = UUID()
    let name: String
    let image: UIImage
    let x: Double
    let y: Double
    let locationName: String
}
