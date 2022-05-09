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
    
    // initialize connection to watch...also conatins core data model
    @StateObject private var phoneViewModel = PhoneViewModel()
    
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
                .environment(\.managedObjectContext, phoneViewModel.dataController.container.viewContext)
                .environmentObject(mapViewModel)
                .environmentObject(cloudViewModel)
                .environmentObject(phoneViewModel)
                .onOpenURL { url in
                    Task {
                        await cloudViewModel.checkDeepLink(url: url, isFromNoti: false)
                    }
                }
                .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .accentColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
    }
}
