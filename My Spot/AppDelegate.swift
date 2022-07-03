//
//  AppDelegate.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/7/22.
//

import UIKit
import CloudKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
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
        } else if notification?.notificationType == .database {
            if UserDefaults.standard.valueExists(forKey: "badgeplaylists") {
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "badgeplaylists") + 1, forKey: "badgeplaylists")
            } else {
                UserDefaults.standard.set(1, forKey: "badgeplaylists")
            }
        }
        completionHandler(.noData)
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        // accept remote share invite
        let shareStore = CoreDataStack.shared.sharedPersistentStore
        let persistentContainer = CoreDataStack.shared.persistentContainer
        persistentContainer.acceptShareInvitations(from: [cloudKitShareMetadata], into: shareStore) { _, error in
            if let error = error {
                DispatchQueue.main.async {
                    CoreDataStack.shared.failedToRecieve = true
                }
                print("acceptShareInvitation error :\(error)")
            } else {
                DispatchQueue.main.async {
                    CoreDataStack.shared.recievedShare = true
                }
            }
        }
    }
}
