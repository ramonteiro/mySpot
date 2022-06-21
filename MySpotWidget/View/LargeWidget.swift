//
//  LargeWidget.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import SwiftUI

struct LargeWidgetView: View {
    let entry: Provider.Entry
    let mapViewModel: WidgetLocationManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            VStack(spacing: 5) {
                WidgetHeader(locationName: "Near ".localized() + entry.locationName)
                    .padding(.vertical, 5)
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        WidgetTile(spot: entry.spot[0], distance: mapViewModel.calculateDistance(x: entry.spot[0].x, y: entry.spot[0].y, x2: entry.userx, y2: entry.usery))
                            .padding([.horizontal, .bottom], 5)
                        WidgetTile(spot: entry.spot[1], distance: mapViewModel.calculateDistance(x: entry.spot[1].x, y: entry.spot[1].y, x2: entry.userx, y2: entry.usery))
                            .padding([.horizontal, .bottom], 5)
                    }
                    HStack(spacing: 0) {
                        WidgetTile(spot: entry.spot[2], distance: mapViewModel.calculateDistance(x: entry.spot[2].x, y: entry.spot[2].y, x2: entry.userx, y2: entry.usery))
                            .padding([.horizontal, .bottom], 5)
                        WidgetTile(spot: entry.spot[3], distance: mapViewModel.calculateDistance(x: entry.spot[3].x, y: entry.spot[3].y, x2: entry.userx, y2: entry.usery))
                            .padding([.horizontal, .bottom], 5)
                    }
                }
            }
        }
    }
}
