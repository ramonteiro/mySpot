//
//  AppDelegate.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/7/22.
//

import UIKit
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        if notification?.notificationType == .query {
            let queryNotification = notification as? CKQueryNotification
            if let recordid = queryNotification?.recordFields?["id"] as? String {
                if UserDefaults.standard.valueExists(forKey: "badge") {
                    UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "badge") + 1, forKey: "badge")
                } else {
                    UserDefaults.standard.set(1, forKey: "badge")
                }
                if UserDefaults.standard.valueExists(forKey: "newSpotNotiRecords") {
                    var recordArray: [String] = UserDefaults.standard.stringArray(forKey: "newSpotNotiRecords") ?? []
                    recordArray.append(recordid)
                    UserDefaults.standard.set(recordArray, forKey: "newSpotNotiRecords")
                } else {
                    let recordArray: [String] = [recordid]
                    UserDefaults.standard.set(recordArray, forKey: "newSpotNotiRecords")
                }
            }
        }
        completionHandler(.noData)
    }
}
