//
//  My_SpotApp.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

@main
struct My_SpotApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var showSharedSpotSheet = false
    
    // initialize core data
    @StateObject private var dataController = CoreDataManager()
    
    // initialize mapViewModel
    @StateObject private var mapViewModel = MapViewModel()
    
    // initialize iCloudViewModel
    @StateObject private var cloudViewModel = CloudKitViewModel()
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(mapViewModel)
                .environmentObject(cloudViewModel)
                .onOpenURL { url in
                    Task {
                        await cloudViewModel.checkDeepLink(url: url, isFromNoti: false)
                    }
                }
                .onAppear {
                    if (UserDefaults.standard.valueExists(forKey: "systemcolor")) {
                        cloudViewModel.systemColorIndex = UserDefaults.standard.integer(forKey: "systemcolor")
                    } else {
                        UserDefaults.standard.set(0, forKey: "systemcolor")
                    }
                    if UIApplication.shared.applicationIconBadgeNumber > 0 {
                        UIApplication.shared.applicationIconBadgeNumber = UIApplication.shared.applicationIconBadgeNumber - 1
                    }
                }
                .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .accentColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
    }
}
