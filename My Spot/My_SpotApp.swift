//
//  My_SpotApp.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

@main
struct My_SpotApp: App {
    
    // initialize core data
    @StateObject private var dataController = CoreDataManager()
    
    // initialize mapViewModel
    @StateObject private var mapViewModel = MapViewModel()
    
    //initialize iCloudViewModel
    @StateObject private var cloudViewModel = CloudKitViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(mapViewModel: mapViewModel, cloudViewModel: cloudViewModel).environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }
}
