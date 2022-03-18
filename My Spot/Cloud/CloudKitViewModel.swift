//
//  CloudKitViewModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import SwiftUI
import CloudKit

class CloudKitViewModel: ObservableObject {
    
    @Published var isSignedInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var spots: [SpotFromCloud] = []
    @Published var shared: [SpotFromCloud] = []
    @Published var userID: String = ""
    @Published var canRefresh = false
    
    init() {
        getiCloudStatus()
    }
    
    func checkDeepLink(url: URL) {
        
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            return
        }
        let pred = NSPredicate(format: "id == %@", host)
        let query = CKQuery(recordType: "Spots", predicate: pred)
        let operation = CKQueryOperation(query: query)
        var returnedSpots: [SpotFromCloud] = []
        shared = []
        
        operation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let description = record["description"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
                guard let type = record["type"] as? String else { return }
                guard let emoji = record["emoji"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let locationName = record["locationName"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                let imageURL = image.fileURL
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: type, emoji: emoji, imageURL: imageURL ?? URL(fileURLWithPath: "none"), likes: likes, locationName: locationName, userID: user, record: record))
            case .failure(let error):
                print("FETCH ERROR: \(error)")
            }
        }
        
        operation.queryResultBlock = { [weak self] cur in
            DispatchQueue.main.async {
                self?.shared = returnedSpots
            }
        }
        addOperation(operation: operation)
    }
    
    func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self?.error = CloudKitError.iCloudAccountNotDetermined.rawValue
                case .available:
                    self?.isSignedInToiCloud = true
                    self?.fetchUserID()
                case .restricted:
                    self?.error = CloudKitError.iCloudAccountRestricted.rawValue
                case .noAccount:
                    self?.error = CloudKitError.iCloudAccountNotFound.rawValue
                case .temporarilyUnavailable:
                    self?.error = CloudKitError.iCloudAccountUnavailable.rawValue
                @unknown default:
                    self?.error = CloudKitError.iCloudAccountUnknown.rawValue
                }
            }
        }
    }
    
    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountUnavailable
        case iCloudAccountUnknown
    }
    
    private func compressImage(image: UIImage) -> UIImage {
            let resizedImage = image.aspectFittedToHeight(300)
            resizedImage.jpegData(compressionQuality: 0.9)

            return resizedImage
    }
    
    func addSpotToPublic(name: String, founder: String, date: String, locationName: String, x: Double, y: Double, description: String, type: String, image: UIImage, emoji: String) -> String {
        let newSpot = CKRecord(recordType: "Spots")
        newSpot["name"] = name
        newSpot["founder"] = founder
        newSpot["description"] = description
        newSpot["date"] = date
        newSpot["locationName"] = locationName
        newSpot["location"] = CLLocation(latitude: x, longitude: y)
        newSpot["type"] = type
        newSpot["emoji"] = emoji
        newSpot["id"] = UUID().uuidString
        newSpot["userID"] = userID
        newSpot["likes"] = 0
        
        if let imageData = compressImage(image: image).pngData() {
            do {
                let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                let url = URL(fileURLWithPath: path)
                try imageData.write(to: url)
                let asset = CKAsset(fileURL: url)
                newSpot["image"] = asset
                saveSpotPublic(record: newSpot)
                return newSpot.recordID.recordName
            } catch {
                print(error)
                return ""
            }
        }
        return ""
    }
    
    private func fetchUserID() {
        CKContainer.default().fetchUserRecordID { [weak self] returnedID, returnedError in
            DispatchQueue.main.async {
                if let id = returnedID {
                    self?.userID = id.recordName
                }
            }
        }
    }
    
    private func saveSpotPublic(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
        }
    }
    
    func fetchSpotPublic(userLocation: CLLocation, type: String) {
        var pred = NSPredicate(value: true)
        if (type != "none") {
            pred = NSPredicate(format: "name CONTAINS[c] %@", type)
        }
        let query = CKQuery(recordType: "Spots", predicate: pred)
        let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
        let creation = NSSortDescriptor(key: "creationDate", ascending: false)
        query.sortDescriptors = [distance, creation]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = CloudKitConst.maxLoadPerFetch
        var returnedSpots: [SpotFromCloud] = []
        
        operation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let description = record["description"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
                guard let type = record["type"] as? String else { return }
                guard let emoji = record["emoji"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let locationName = record["locationName"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                let imageURL = image.fileURL
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: type, emoji: emoji, imageURL: imageURL ?? URL(fileURLWithPath: "none"), likes: likes, locationName: locationName, userID: user, record: record))
            case .failure(let error):
                print("FETCH ERROR: \(error)")
            }
        }
        
        operation.queryResultBlock = { [weak self] cur in
            print("RETURNED RESULT: \(cur)")
            DispatchQueue.main.async {
                self?.spots = returnedSpots
                self?.fetchMoreSpotsPublic(cursor: try? cur.get())
            }
        }
        addOperation(operation: operation)
    }
    
    
    
    func updateSpotPublic(spot: Spot, newName: String, newDescription: String, newFounder: String, newType: String, newEmoji: String) {
        let recordID = CKRecord.ID(recordName: spot.dbid!)
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let returnedRecord = returnedRecord else {return}
                returnedRecord["name"] = newName
                returnedRecord["description"] = newDescription
                returnedRecord["type"] = newType
                returnedRecord["emoji"] = newEmoji
                
                self?.saveSpotPublic(record: returnedRecord)
            }
        }
    }
    
    func likeSpot(spot: SpotFromCloud, like: Bool) {
        if (spot.likes < 1 && !like) {
            return
        }
        let record = spot.record
        if (like) {
            record["likes"]! += 1
        } else {
            record["likes"]! -= 1
        }
        saveSpotPublic(record: record)
        return
    }
    
    func fetchMoreSpotsPublic(cursor:CKQueryOperation.Cursor?)  {

        guard let cursorChecked = cursor else { return }
        if spots.count > CloudKitConst.maxLoadTotal - 1 {
            return
        }
        let queryoperation = CKQueryOperation(cursor: cursorChecked)
        queryoperation.resultsLimit = CloudKitConst.maxLoadPerFetch
        var returnedSpots: [SpotFromCloud] = []
        queryoperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let description = record["description"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
                guard let type = record["type"] as? String else { return }
                guard let emoji = record["emoji"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let locationName = record["locationName"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                let imageURL = image.fileURL
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: type, emoji: emoji, imageURL: imageURL ?? URL(fileURLWithPath: "none"), likes: likes, locationName: locationName, userID: user, record: record))
            case .failure(let error):
                print("FETCH ERROR: \(error)")
            }
        }
        queryoperation.queryResultBlock = { [weak self] returnedResult in
            print("RETURNED RESULT: \(returnedResult)")
            DispatchQueue.main.async {
                self?.spots += returnedSpots
                self?.fetchMoreSpotsPublic(cursor: try? returnedResult.get())
            }
        }
        addOperation(operation: queryoperation)
    }
    
    private func addOperation(operation: CKDatabaseOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    func deleteSpotPublic(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let spot = spots[index]
        let record = spot.record
        
        CKContainer.default().publicCloudDatabase.delete(withRecordID: record.recordID) { [weak self] returnedRecordID, returnedError in
            DispatchQueue.main.async {
                self?.spots.remove(at: index)
            }
        }
    }
    
    func shareSheet(index i: Int) {
        let url = URL(string: "myspot://" + (spots[i].id))
        let activityView = UIActivityViewController(activityItems: ["Check out, \"\(spots[i].name)\(spots[i].emoji)\" on My Spot! ", url!, "\n\nIf you don't have My Spot, get it on the Appstore here: ", URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)

        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
}
