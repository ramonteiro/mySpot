//
//  WidgetEntry.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import SwiftUI

struct WidgetEntryView: View {
    let entry: Provider.Entry
    let mapViewModel: WidgetLocationManager
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View {
        if !entry.isNoLocation {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry, mapViewModel: mapViewModel)
            case .systemMedium:
                MediumWidgetView(entry: entry, mapViewModel: mapViewModel)
            default:
                LargeWidgetView(entry: entry, mapViewModel: mapViewModel)
            }
        } else {
            Text("Loading".localized() + "...")
        }
    }
}
