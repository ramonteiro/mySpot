//
//  SpotTimeLineEntry.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/20/22.
//

import WidgetKit

struct SpotEntry: TimelineEntry {
    let date = Date()
    let locationName: String
    let userx: Double
    let usery: Double
    let isNoLocation: Bool
    let spot: [Spot]
}
