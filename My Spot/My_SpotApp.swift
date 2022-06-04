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
        UITableView.appearance().showsVerticalScrollIndicator = false
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataStack.shared.context)
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
                .onAppear {
                    let color = UIColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var alpha: CGFloat = 0

                    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(green), forKey: "colorg")
                    UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(blue), forKey: "colorb")
                    UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(red), forKey: "colorr")
                    UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(alpha), forKey: "colora")
                }
        }
    }
}
