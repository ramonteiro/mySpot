//
//  My_SpotApp.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

@main
struct My_SpotApp: App {
    
    @StateObject var watchViewModel = WatchViewModel()
    @StateObject var mapViewModel = WatchLocationManager()
    let systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow, .gray]
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView(mapViewModel: mapViewModel, watchViewModel: watchViewModel)
                    .accentColor(!(UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.valueExists(forKey: "colora") ?? false) ? .red :
                                    ((UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0) != systemColorArray.count - 1) ? systemColorArray[UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0] : Color(uiColor: UIColor(red: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorr") ?? 0), green: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorg") ?? 0), blue: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorb") ?? 0), alpha: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colora") ?? 0))))
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
