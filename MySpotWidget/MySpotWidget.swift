//
//  MySpotWidget.swift
//  MySpotWidget
//
//  Created by Isaac Paschall on 5/4/22.
//

import WidgetKit
import SwiftUI

@main
struct WidgetMain: Widget {
    var mapViewModel = WidgetLocationManager()
    var cloudViewModel = CloudKitViewModel()
    private let kind = "MySpotWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider(cloudViewModel: cloudViewModel, mapViewModel: mapViewModel)) { entry in
            WidgetEntryView(entry: entry, mapViewModel: mapViewModel)
        }
        .configurationDisplayName("Spots Near Me".localized())
        .description("Shows Spots Closest To You".localized())
        .supportedFamilies([.systemLarge, .systemSmall, .systemMedium])
    }
}
