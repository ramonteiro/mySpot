//
//  My_SpotApp.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

@main
struct My_SpotApp: App {
    
    @StateObject var mapViewModel = WatchLocationManager()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(mapViewModel: mapViewModel)
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Localizable", bundle: .main, value: self, comment: self)
    }
}
