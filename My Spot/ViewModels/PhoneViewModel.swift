//
//  PhoneViewModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/6/22.
//

import Foundation
import WatchConnectivity
import CloudKit
import UIKit

class PhoneViewModel : NSObject,  WCSessionDelegate, ObservableObject {
    
    var dataController = CoreDataManager()
    var listOfDownloadsInSession: [String] = []
    var session: WCSession
    var message = "Unknown"
    
    init(session: WCSession = .default) {
        self.session = session
        super.init()
        session.delegate = self
        session.activate()
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let message = message["id"] as? String ?? "Unknown"
        if message != "Uknown" && !listOfDownloadsInSession.contains(message) {
            Task {
                do {
                    try await self.downloadSpot(id: message)
                    listOfDownloadsInSession.append(message)
                } catch {
                    print("Error downloading spot")
                }
            }
        }
    }
    
    func save(spot: SpotFromCloud) {
        let newSpot = Spot(context: dataController.container.viewContext)
        newSpot.founder = spot.founder
        newSpot.details = spot.description
        if let data = try? Data(contentsOf: spot.imageURL), let image1 = UIImage(data: data) {
            newSpot.image = image1
        }
        if let image2 = spot.image2URL {
            newSpot.image2 = image2
        }
        if let image3 = spot.image3URL {
            newSpot.image3 = image3
        }
        newSpot.locationName = spot.locationName
        newSpot.name = spot.name
        newSpot.x = spot.location.coordinate.latitude
        newSpot.y = spot.location.coordinate.longitude
        newSpot.isPublic = false
        newSpot.fromDB = false
        if let userid = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") {
            if spot.userID != userid {
                newSpot.fromDB = true
            }
        }
        newSpot.tags = spot.type
        newSpot.date = spot.date
        if spot.customLocation == 1 {
            newSpot.wasThere = false
        } else {
            newSpot.wasThere = true
        }
        newSpot.id = UUID()
        newSpot.dbid = spot.record.recordID.recordName
        do {
            try dataController.container.viewContext.save()
        } catch {
            print("error saving: \(error)")
        }
    }
    
    func downloadSpot(id: String) async throws {
        let record = try await CKContainer.default().publicCloudDatabase.record(for: CKRecord.ID(recordName: id))
        DispatchQueue.main.async {
            guard let name = record["name"] as? String else { return }
            guard let founder = record["founder"] as? String else { return }
            guard let date = record["date"] as? String else { return }
            guard let location = record["location"] as? CLLocation else { return }
            guard let customLocation = record["customLocation"] as? Int else { return }
            var types = ""
            var description = ""
            var locationName = ""
            if let typeCheck = record["type"] as? String {
                types = typeCheck
            }
            if let descriptionCheck = record["description"] as? String {
                description = descriptionCheck
            }
            if let locationNameCheck = record["locationName"] as? String {
                locationName = locationNameCheck
            }
            guard let likes = record["likes"] as? Int else { return }
            guard let id = record["id"] as? String else { return }
            guard let user = record["userID"] as? String else { return }
            guard let image = record["image"] as? CKAsset else { return }
            var isMultipleImages = 0
            if let m = record["isMultipleImages"] as? Int {
                isMultipleImages = m
            }
            var inappropriate = 0
            var offensive = 0
            var spam = 0
            var dangerous = 0
            if let inna = record["inappropriate"] as? Int {
                inappropriate = inna
            }
            if let offen = record["offensive"] as? Int {
                offensive = offen
            }
            if let sp = record["spam"] as? Int {
                spam = sp
            }
            if let dan = record["dangerous"] as? Int {
                dangerous = dan
            }
            let imageURL = image.fileURL
            if let image3Check = record["image3"] as? CKAsset {
                guard let image2Check = record["image2"] as? CKAsset else { return }
                let image3URL = image3Check.fileURL ?? URL(fileURLWithPath: "none")
                let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                guard let data2 = try? Data(contentsOf: image2URL) else { return }
                guard let data3 = try? Data(contentsOf: image3URL) else { return }
                let image2 = UIImage(data: data2)
                let image3 = UIImage(data: data3)
                self.save(spot: SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: image3, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, record: record))
            } else if let image2Check = record["image2"] as? CKAsset {
                let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                guard let data2 = try? Data(contentsOf: image2URL) else { return }
                let image2 = UIImage(data: data2)
                self.save(spot: SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, record: record))
            } else {
                self.save(spot: SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, record: record))
            }
        }
    }
}
