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
    @Published var isFetching = false
    @Published var maxTotalfetches = 10
    
    init() {
        getiCloudStatus()
        if (UserDefaults.standard.valueExists(forKey: "maxTotalFetches")) {
            maxTotalfetches = UserDefaults.standard.value(forKey: "maxTotalFetches") as! Int
        }
    }
    
    func deleteSpot(id: CKRecord.ID) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: id) { returnedID, returnedError in
            print(returnedID ?? "None")
        }
    }
    
    func checkDeepLink(url: URL) {
        
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            return
        }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: CKRecord.ID(recordName: host)) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let record = returnedRecord else {return}
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
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
                let imageURL = image.fileURL
                var image2URL = URL(fileURLWithPath: "none")
                var image3URL = URL(fileURLWithPath: "none")
                if let image3 = record["image3"] as? CKAsset {
                    guard let image2 = record["image2"] as? CKAsset else { return }
                    image3URL = image3.fileURL ?? URL(fileURLWithPath: "none")
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                } else if let image2 = record["image2"] as? CKAsset {
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                }
                self?.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2URL , image3URL: image3URL , likes: likes, locationName: locationName, userID: user, record: record)]
            }
        }
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
    
    func compressImage(image: UIImage) -> UIImage {
            let resizedImage = image.aspectFittedToHeight(300)
        resizedImage.jpegData(compressionQuality: 1.0)

            return resizedImage
    }
    
    func addSpotToPublic(name: String, founder: String, date: String, locationName: String, x: Double, y: Double, description: String, type: String, image: Data, image2: Data?, image3: Data?) -> String {
        let newSpot = CKRecord(recordType: "Spots")
        newSpot["name"] = name
        newSpot["founder"] = founder
        newSpot["description"] = description
        newSpot["date"] = date
        newSpot["locationName"] = locationName
        newSpot["location"] = CLLocation(latitude: x, longitude: y)
        newSpot["type"] = type
        newSpot["id"] = UUID().uuidString
        newSpot["userID"] = userID
        newSpot["likes"] = 0
        
        if let image2 = image2 {
            do {
                let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                let url = URL(fileURLWithPath: path)
                try image2.write(to: url)
                let asset = CKAsset(fileURL: url)
                newSpot["image2"] = asset
            } catch {
                print(error)
                return ""
            }
        }
        
        if let image3 = image3 {
            do {
                let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                let url = URL(fileURLWithPath: path)
                try image3.write(to: url)
                let asset = CKAsset(fileURL: url)
                newSpot["image3"] = asset
            } catch {
                print(error)
                return ""
            }
        }
        
        do {
            let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
            let url = URL(fileURLWithPath: path)
            try image.write(to: url)
            let asset = CKAsset(fileURL: url)
            newSpot["image"] = asset
            saveSpotPublic(record: newSpot)
            return newSpot.recordID.recordName
        } catch {
            print(error)
            return ""
        }
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
        isFetching = true
        var pred = NSPredicate(value: true)
        if (type != "none") {
            pred = NSPredicate(format: "name CONTAINS[c] %@", type)
        }
        let query = CKQuery(recordType: "Spots", predicate: pred)
        let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
        let creation = NSSortDescriptor(key: "creationDate", ascending: false)
        query.sortDescriptors = [distance, creation]
        
        let operation = CKQueryOperation(query: query)
        operation.resultsLimit = 10
        var returnedSpots: [SpotFromCloud] = []
        
        operation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
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
                let imageURL = image.fileURL
                var image2URL = URL(fileURLWithPath: "none")
                var image3URL = URL(fileURLWithPath: "none")
                if let image3 = record["image3"] as? CKAsset {
                    guard let image2 = record["image2"] as? CKAsset else { return }
                    image3URL = image3.fileURL ?? URL(fileURLWithPath: "none")
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                } else if let image2 = record["image2"] as? CKAsset {
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                }
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2URL , image3URL: image3URL , likes: likes, locationName: locationName, userID: user, record: record))
            case .failure(let error):
                print("FETCH ERROR: \(error)")
                self.isFetching = false
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
    
    
    
    func updateSpotPublic(spot: Spot, newName: String, newDescription: String, newFounder: String, newType: String, imageChanged: Bool, image: Data?, image2: Data?, image3: Data?) {
        let recordID = CKRecord.ID(recordName: spot.dbid!)
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let returnedRecord = returnedRecord else {return}
                returnedRecord["name"] = newName
                returnedRecord["description"] = newDescription
                returnedRecord["type"] = newType
                returnedRecord["founder"] = newFounder
                
                if (imageChanged) {
                    if let image3 = image3 {
                        do {
                            let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                            let url = URL(fileURLWithPath: path)
                            try image3.write(to: url)
                            let asset = CKAsset(fileURL: url)
                            returnedRecord["image3"] = asset
                        } catch {
                            print(error)
                            return
                        }
                    } else {
                        returnedRecord["image3"] = nil
                    }
                    
                    if let image2 = image2 {
                        do {
                            let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                            let url = URL(fileURLWithPath: path)
                            try image2.write(to: url)
                            let asset = CKAsset(fileURL: url)
                            returnedRecord["image2"] = asset
                        } catch {
                            print(error)
                            return
                        }
                    } else {
                        returnedRecord["image2"] = nil
                        returnedRecord["image3"] = nil
                    }
                    
                    if let image = image {
                        do {
                            let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                            let url = URL(fileURLWithPath: path)
                            try image.write(to: url)
                            let asset = CKAsset(fileURL: url)
                            returnedRecord["image"] = asset
                        } catch {
                            print(error)
                            return
                        }
                    }
                }
                
                self?.saveSpotPublic(record: returnedRecord)
            }
        }
    }
    
    func likeSpot(spot: SpotFromCloud, like: Bool) async -> Bool {
        if (spot.likes < 1 && !like) {
            return false
        }
        let record = spot.record
        if (like) {
            record["likes"]! += 1
        } else {
            record["likes"]! -= 1
        }
        do {
            try await CKContainer.default().publicCloudDatabase.save(record)
            return true
        } catch {
            return false
        }
    }
    
    func fetchMoreSpotsPublic(cursor:CKQueryOperation.Cursor?)  {

        guard let cursorChecked = cursor else {
            isFetching = false
            return
        }
        if spots.count > maxTotalfetches - 1 {
            isFetching = false
            return
        }
        let queryoperation = CKQueryOperation(cursor: cursorChecked)
        queryoperation.resultsLimit = 10
        var returnedSpots: [SpotFromCloud] = []
        queryoperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                guard let location = record["location"] as? CLLocation else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
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
                let imageURL = image.fileURL
                var image2URL = URL(fileURLWithPath: "none")
                var image3URL = URL(fileURLWithPath: "none")
                if let image3 = record["image3"] as? CKAsset {
                    guard let image2 = record["image2"] as? CKAsset else { return }
                    image3URL = image3.fileURL ?? URL(fileURLWithPath: "none")
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                } else if let image2 = record["image2"] as? CKAsset {
                    image2URL = image2.fileURL ?? URL(fileURLWithPath: "none")
                }
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2URL , image3URL: image3URL , likes: likes, locationName: locationName, userID: user, record: record))
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
    
    func shareSheet(index i: Int) {
        let activityView = UIActivityViewController(activityItems: ["Check out, \"\(spots[i].name)\" on My Spot! ", URL(string: "myspot://" + (spots[i].record.recordID.recordName)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ", URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
    
    func shareSheetFromLocal(id: String, name: String) {
        let activityView = UIActivityViewController(activityItems: ["Check out, \"\(name)\" on My Spot! ", URL(string: "myspot://" + (id)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ", URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
    }
    
    func isMySpot(user: String) -> Bool {
        if userID == user {
            return true
        }
        return false
    }
}
