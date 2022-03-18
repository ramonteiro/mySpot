//
//  My_SpotApp.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

@main
struct My_SpotApp: App {
    
    @State private var showSharedSpotSheet = false
    
    // initialize core data
    @StateObject private var dataController = CoreDataManager()
    
    // initialize mapViewModel
    @StateObject private var mapViewModel = MapViewModel()
    
    // initialize iCloudViewModel
    @StateObject private var cloudViewModel = CloudKitViewModel()
    
    // initialize Network Monitor
    @StateObject private var networkViewModel = NetworkMonitor()
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(mapViewModel)
                .environmentObject(cloudViewModel)
                .environmentObject(networkViewModel)
                .onOpenURL { url in
                    cloudViewModel.checkDeepLink(url: url)
                }
        }
    }
}
