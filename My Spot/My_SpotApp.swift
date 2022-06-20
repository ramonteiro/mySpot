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
    @StateObject private var phoneViewModel = PhoneViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var cloudViewModel = CloudKitViewModel()
    @StateObject private var tabController = TabController()
    
    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemBlue
        UITableView.appearance().showsVerticalScrollIndicator = false
        UIScrollView.appearance().keyboardDismissMode = .interactive
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataStack.shared.context)
                .environmentObject(mapViewModel)
                .environmentObject(cloudViewModel)
                .environmentObject(phoneViewModel)
                .environmentObject(tabController)
                .onOpenURL { url in
                    openDeepLink(url: url)
                }
                .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .accentColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
    }
    
    private func openDeepLink(url: URL) {
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else { return }
        if host[0] == "_" {
            if let id = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") {
                if id == host {
                    tabController.open(Tab.profile)
                } else {
                    cloudViewModel.deepAccount = host
                    cloudViewModel.AccountModelToggle.toggle()
                }
            } else {
                cloudViewModel.deepAccount = host
                cloudViewModel.AccountModelToggle.toggle()
            }
        } else {
            Task {
                await cloudViewModel.checkDeepLink(host: host)
            }
        }
    }
}
