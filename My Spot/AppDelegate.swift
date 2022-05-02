//
//  AppDelegate.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/2/22.
//

import Foundation
import NotificationCenter



class AppDelegate: NSObject, UIApplicationDelegate {
    
    var notificationManager = NotificationManager()
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) async -> UIBackgroundFetchResult {
        for i in userInfo {
            print("\(i.key) + \(i.value)")
        }
//        guard let id = userInfo["id"] as? [String: AnyObject] else { return .failed }
//        for i in id {
//            notificationManager.currentNotificationText?.append(i.key)
//            print("New Noti: \(i.key) or maybe: \(i.value)")
//        }
        
        return .newData
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    
}

class NotificationManager : ObservableObject {
    @Published var currentNotificationText : [String]?
}
