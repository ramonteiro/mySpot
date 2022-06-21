//
//  SmallWidget.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import SwiftUI

struct SmallWidgetView: View {
    let entry: Provider.Entry
    let mapViewModel: WidgetLocationManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
            VStack(spacing: 5) {
                WidgetHeader(locationName: entry.locationName)
                    .padding(.vertical, 5)
                HStack(spacing: 0) {
                    WidgetTile(spot: entry.spot[0], distance: mapViewModel.calculateDistance(x: entry.spot[0].x, y: entry.spot[0].y, x2: entry.userx, y2: entry.usery))
                        .padding([.horizontal, .bottom], 5)
                }
            }
        }
        .widgetURL(URL(string: "myspot://" + (entry.spot[0].spotid))!)
    }
}
