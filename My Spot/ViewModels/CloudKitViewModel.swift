//
//  CloudKitViewModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import SwiftUI
import CloudKit

class CloudKitViewModel: ObservableObject {
    
    @Published var notiPlaylistOn = false
    @Published var notiNewSpotOn = false
    @Published var systemColorIndex = 0
    @Published var systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow]
    @Published var isSignedInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var spots: [SpotFromCloud] = []
    @Published var shared: [SpotFromCloud] = []
    @Published var userID: String = ""
    @Published var canRefresh = false
    @Published var isFetching = false
    @Published var maxTotalfetches = 10
    @Published var isError = false
    @Published var isErrorMessage = ""
    @Published var isPostError = false
    @Published var isPostErrorID = ""
    @Published var fetchedlikes = 0
    
    init() {
        getiCloudStatus()
        setUserDefaults()
    }
    
    private func setUserDefaults() {
        if (UserDefaults.standard.valueExists(forKey: "maxTotalFetches")) {
            maxTotalfetches = UserDefaults.standard.value(forKey: "maxTotalFetches") as! Int
        }
        if (UserDefaults.standard.valueExists(forKey: "discovernot")) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings {[weak self] settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .authorized {
                        self?.notiNewSpotOn = true
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "discovernot")
        }
        if (UserDefaults.standard.valueExists(forKey: "playlistnot")) {
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings {[weak self] settings in
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .authorized {
                        self?.notiNewSpotOn = true
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "playlistnot")
        }
    }
    
    func deleteSpot(id: CKRecord.ID) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: id) {[weak self] returnedID, returnedError in
            DispatchQueue.main.async {
                if (returnedError != nil) {
                    self?.isErrorMessage = cloudkitErrorMsg.delete
                    self?.isError.toggle()
                }
            }
        }
    }
    
    func checkDeepLink(url: URL) async {
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            isErrorMessage = cloudkitErrorMsg.dpLink
            isError.toggle()
            return
        }
        do {
            let record = try await CKContainer.default().publicCloudDatabase.record(for: CKRecord.ID(recordName: host))
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
                self.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: image3, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
            } else if let image2Check = record["image2"] as? CKAsset {
                let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                guard let data2 = try? Data(contentsOf: image2URL) else { return }
                let image2 = UIImage(data: data2)
                self.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
            } else {
                self.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
            }
        } catch {
            self.isErrorMessage = cloudkitErrorMsg.dpLink
            self.isError.toggle()
        }
    }
    /*
    func checkDeepLink(url: URL) {
        
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            isErrorMessage = cloudkitErrorMsg.dpLink
            isError.toggle()
            return
        }
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: CKRecord.ID(recordName: host)) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let record = returnedRecord else {
                    self?.isErrorMessage = cloudkitErrorMsg.dpLink
                    self?.isError.toggle()
                    return
                }
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
                    self?.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: image3, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
                } else if let image2Check = record["image2"] as? CKAsset {
                    let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                    guard let data2 = try? Data(contentsOf: image2URL) else { return }
                    let image2 = UIImage(data: data2)
                    self?.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: image2 , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
                } else {
                    self?.shared = [SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record)]
                }
            }
        }
    }
     */
    
    func getLikes(idString: String) {
        if idString.isEmpty {
            return
        }
        let id = CKRecord.ID(recordName: idString)
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: id) {[weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let returnedRecord = returnedRecord else {
                    return
                }
                guard let likes = returnedRecord["likes"] as? Int else { return }
                self?.fetchedlikes = likes
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
        let resizedImage = image.aspectFittedToHeight(200)
        resizedImage.jpegData(compressionQuality: 1.0)
        
        return resizedImage
    }
    
    func addSpotToPublic(name: String, founder: String, date: String, locationName: String, x: Double, y: Double, description: String, type: String, image: Data, image2: Data?, image3: Data?, isMultipleImages: Int) -> String {
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
        newSpot["isMultipleImages"] = isMultipleImages
        newSpot["offensive"] = 0
        newSpot["inappropriate"] = 0
        newSpot["spam"] = 0
        newSpot["dangerous"] = 0
        
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
        CKContainer.default().publicCloudDatabase.save(record) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                if (returnedError != nil) {
                    self?.isPostErrorID = record.recordID.recordName
                    self?.isErrorMessage = cloudkitErrorMsg.create
                    self?.isError.toggle()
                    self?.isPostError.toggle()
                }
            }
        }
    }
    
    func fetchImages(id: String) async -> [UIImage?] {
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(for: [CKRecord.ID(recordName: id)], desiredKeys: ["image2", "image3"])
            let record = results[CKRecord.ID(recordName: id)]
            switch record {
            case .success(let record):
                if let image3Check = record["image3"] as? CKAsset {
                    guard let image2Check = record["image2"] as? CKAsset else { return [] }
                    let image3URL = image3Check.fileURL ?? URL(fileURLWithPath: "none")
                    let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                    guard let data2 = try? Data(contentsOf: image2URL) else { return [] }
                    guard let data3 = try? Data(contentsOf: image3URL) else { return [] }
                    let image2 = UIImage(data: data2)
                    let image3 = UIImage(data: data3)
                    return [image2, image3]
                } else if let image2Check = record["image2"] as? CKAsset {
                    let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                    guard let data2 = try? Data(contentsOf: image2URL) else { return [] }
                    let image2 = UIImage(data: data2)
                    return [image2]
                } else {
                    return []
                }
            case .failure(let error):
                print("FETCH ERROR: \(error)")
                return []
            case .none:
                return []
            }
        } catch {
            return []
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
        operation.desiredKeys = ["name", "founder", "date", "location", "likes", "inappropriate", "offensive", "dangerous", "spam", "id", "userID", "image", "type", "isMultipleImages"]
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
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record))
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
    
    
    
    func updateSpotPublic(spot: Spot, newName: String, newDescription: String, newFounder: String, newType: String, imageChanged: Bool, image: Data?, image2: Data?, image3: Data?, isMultipleImages: Int) {
        let recordID = CKRecord.ID(recordName: spot.dbid!)
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { [weak self] returnedRecord, returnedError in
            DispatchQueue.main.async {
                guard let returnedRecord = returnedRecord else {return}
                returnedRecord["name"] = newName
                returnedRecord["description"] = newDescription
                returnedRecord["type"] = newType
                returnedRecord["founder"] = newFounder
                returnedRecord["isMultipleImages"] = isMultipleImages
                
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
        guard let _ = spot.record["likes"] else { return false }
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
    
    func report(spot: SpotFromCloud, report: String) async -> Bool {
        guard let _ = spot.record[report] else { return false }
        let record = spot.record
        record[report]! += 1
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
        queryoperation.desiredKeys = ["name", "founder", "date", "location", "likes", "inappropriate", "offensive", "dangerous", "spam", "id", "userID", "image", "type", "isMultipleImages"]
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
                returnedSpots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record))
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
    
    private func requestPermissionNoti(notiType: Int, fixedLocation: CLLocation?, radiusInKm: CGFloat?) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: options) {[weak self] success, error in
            if !success {
                DispatchQueue.main.async {
                    self?.notiPlaylistOn = false
                    self?.notiNewSpotOn = false
                }
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    if notiType == 1 {
                        self?.subscribeToSharedPlaylist()
                    } else if notiType == 2 {
                        self?.subscribeToNewSpot(fixedLocation: fixedLocation!, radiusInKm: radiusInKm!)
                    }
                }
            }
        }
    }
    
    func unsubscribe(id: CKSubscription.ID) {
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: id) { returnedId, returnedError in
            if let returnedError = returnedError {
                print("\(returnedError)")
            }
        }
    }
    
    func subscribeToNewSpot(fixedLocation: CLLocation, radiusInKm: CGFloat) {
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", fixedLocation, radiusInKm)
        let subscription = CKQuerySubscription(recordType: "Spots", predicate: predicate, subscriptionID: "NewSpotDiscover", options: .firesOnRecordCreation)
        let notification = CKSubscription.NotificationInfo()
        notification.title = "My Spot"
        notification.alertBody = "A new spot was added to your area!"
        notification.soundName = "default"
        notification.shouldBadge = true
        subscription.notificationInfo = notification
        CKContainer.default().publicCloudDatabase.save(subscription) {[weak self] returnedSubscription, returnedError in
            if let returnedError = returnedError {
                print("\(returnedError)")
                DispatchQueue.main.async {
                    self?.notiNewSpotOn = false
                    self?.isErrorMessage = "Unable To Turn On Notifications For New Spots."
                    self?.isError.toggle()
                }
            }
        }
    }
    
    private func subscribeToSharedPlaylist() {
        
    }
    
    func checkIfNotiEnabled() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings {[weak self] settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .denied {
                    self?.notiPlaylistOn = false
                    self?.notiNewSpotOn = false
                }
            }
        }
    }
    
    func subscribeToNoti(notiType: Int, fixedLocation: CLLocation?, radiusInKm: CGFloat?) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings {[weak self] settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .notDetermined {
                    if notiType == 1 {
                        self?.requestPermissionNoti(notiType: notiType, fixedLocation: nil, radiusInKm: nil)
                    } else if notiType == 2 {
                        self?.requestPermissionNoti(notiType: notiType, fixedLocation: fixedLocation, radiusInKm: radiusInKm)
                    }
                } else if settings.authorizationStatus == .denied {
                    self?.notiPlaylistOn = false
                    self?.notiNewSpotOn = false
                    self?.isErrorMessage = "Please enable notifications in settings for My Spot."
                    self?.isError.toggle()
                } else if settings.authorizationStatus == .authorized {
                    if notiType == 1 {
                        self?.subscribeToSharedPlaylist()
                    } else if notiType == 2 {
                        self?.subscribeToNewSpot(fixedLocation: fixedLocation!, radiusInKm: radiusInKm!)
                    }
                }
            }
        }
    }
}
