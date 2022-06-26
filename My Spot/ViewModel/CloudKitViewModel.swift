//
//  CloudKitViewModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import SwiftUI
import CloudKit

final class CloudKitViewModel: ObservableObject {
    
    @Published var notiNewSpotOn = false
    @Published var notiSharedOn = false
    @Published var systemColorIndex = 0
    @Published var systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow, .gray]
    @Published var isSignedInToiCloud: Bool = false
    @Published var accountStatus: CKAccountStatus?
    @Published var sharedSpotToggle = false
    @Published var AccountModelToggle = false
    @Published var isFetching = false
    @Published var isError = false
    @Published var notiPermission = 0 // 0: not determined, 1: denied, 2: allowed, 3: provisional, 4: ephemeral, 5: unknown
    @Published var cursorMain: CKQueryOperation.Cursor?
    @Published var cursorAccount: CKQueryOperation.Cursor?
    @Published var cursorUsers: CKQueryOperation.Cursor?
    var shared: SpotFromCloud? = nil
    var deepAccount: String? = nil
    var userID: String = ""
    var isErrorMessage = ""
    var isErrorMessageDetails = ""
    var limit = 5
    var radiusInMeters: Double { Double(UserDefaults.standard.integer(forKey: "savedDistance")) }
    let userKeys = ["userid", "name", "isExplorer", "pronoun", "bio", "tiktok", "instagram", "email"]
    let desiredKeys = ["name", "founder", "date", "location", "likes", "inappropriate", "offensive", "dangerous", "spam", "id", "userID", "type", "isMultipleImages", "locationName", "description", "customLocation", "dateObject"]
    
    init() {
        getiCloudStatus()
        setUserDefaults()
    }
    
    // MARK: - Spots
    
    func deleteSpot(id: String) async throws {
        let ckid = CKRecord.ID(recordName: id)
        try await CKContainer.default().publicCloudDatabase.deleteRecord(withID: ckid)
    }
    
    func checkDeepLink(host: String) async {
        do {
            let record = try await CKContainer.default().publicCloudDatabase.record(for: CKRecord.ID(recordName: host))
            DispatchQueue.main.async {
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                var dateObject: Date?
                if let dateObj = record["dateObject"] as? Date {
                    dateObject = dateObj
                } else {
                    dateObject = nil
                }
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
                let data = try? Data(contentsOf: imageURL ?? URL(fileURLWithPath: ""))
                guard let imageURL = UIImage(data: data ?? Data()) else { return }
                if let image3Check = record["image3"] as? CKAsset {
                    guard let image2Check = record["image2"] as? CKAsset else { return }
                    let image3URL = image3Check.fileURL ?? URL(fileURLWithPath: "none")
                    let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                    guard let data2 = try? Data(contentsOf: image2URL) else { return }
                    guard let data3 = try? Data(contentsOf: image3URL) else { return }
                    let image2 = UIImage(data: data2)
                    let image3 = UIImage(data: data3)
                    self.shared = SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL,  image2URL: image2 , image3URL: image3, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record)
                } else if let image2Check = record["image2"] as? CKAsset {
                    let image2URL = image2Check.fileURL ?? URL(fileURLWithPath: "none")
                    guard let data2 = try? Data(contentsOf: image2URL) else { return }
                    let image2 = UIImage(data: data2)
                    self.shared = SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL,  image2URL: image2 , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record)
                } else {
                    self.shared = SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record)
                }
                DispatchQueue.main.async {
                    self.sharedSpotToggle.toggle()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isErrorMessage = "Unable To Find Spot".localized()
                self.isErrorMessageDetails = "This is due to poor internet connection or the spot you are looking for has been deleted by the founder.".localized()
                self.isError.toggle()
            }
        }
    }
    
    func getLikes(idString: String) async throws -> Int? {
        if idString.isEmpty {
            return nil
        }
        let id = CKRecord.ID(recordName: idString)
        let results = try await CKContainer.default().publicCloudDatabase.records(for: [id], desiredKeys: ["likes"])
        let record = results[id]
        switch record {
        case .success(let record):
            guard let likes = record["likes"] as? Int else { return nil }
            return likes
        case .failure(let error):
            print("\(error)")
            return nil
        case .none:
            print("error fetching likes, none case")
            return nil
        }
    }
    
    func addSpotToPublic(name: String, founder: String, date: String, locationName: String, x: Double, y: Double, description: String, type: String, image: Data, image2: Data?, image3: Data?, isMultipleImages: Int, customLocation: Bool, dateObject: Date?) async throws -> String {
        
        let newSpot = CKRecord(recordType: "Spots")
        if let dateObject = dateObject {
            newSpot["dateObject"] = dateObject
        } else {
            newSpot["dateObject"] = nil
        }
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
        if customLocation {
            newSpot["customLocation"] = 1
        } else {
            newSpot["customLocation"] = 0
        }
        
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
            try await CKContainer.default().publicCloudDatabase.save(newSpot)
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
                    UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(self?.userID, forKey: "userid")
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
    
    func fetchMainImage(id: String) async -> UIImage? {
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(for: [CKRecord.ID(recordName: id)], desiredKeys: ["image"])
            let record = results[CKRecord.ID(recordName: id)]
            switch record {
            case .success(let record):
                guard let imageAsset = record["image"] as? CKAsset else { return nil }
                let imageURL = imageAsset.fileURL ?? URL(fileURLWithPath: "none")
                guard let imageData = try? Data(contentsOf: imageURL) else { return nil }
                let image = UIImage(data: imageData)
                return image
                
            case .failure(let error):
                print("FETCH ERROR: \(error)")
                return nil
            case .none:
                return nil
            }
        } catch {
            return nil
        }
    }
    
    func fetchNotificationSpots(recordid: String) async throws -> SpotFromCloud? {
        let predicate = NSPredicate(format: "id == %@", recordid)
        let query = CKQuery(recordType: "Spots", predicate: predicate)
        
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: desiredKeys, resultsLimit: 1)
        var spot: SpotFromCloud? = nil
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                    guard let name = record["name"] as? String else { return }
                    guard let founder = record["founder"] as? String else { return }
                    guard let date = record["date"] as? String else { return }
                    var dateObject: Date?
                    if let dateObj = record["dateObject"] as? Date {
                        dateObject = dateObj
                    } else {
                        dateObject = nil
                    }
                    guard let location = record["location"] as? CLLocation else { return }
                    guard let likes = record["likes"] as? Int else { return }
                    guard let id = record["id"] as? String else { return }
                    guard let user = record["userID"] as? String else { return }
                    var customLocation = 0
                    if let customLocationChecked = record["customLocation"] as? Int {
                        customLocation = customLocationChecked
                    }
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
                    spot = SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: nil,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record)
                
            case .failure(let error):
                print("\(error)")
                return
            }
        }
        return spot
    }
    
    func fetchSpotPublic(userLocation: CLLocation, filteringBy: String, search: String) async throws -> [SpotFromCloud] {
        DispatchQueue.main.async {
            self.isFetching = true
        }
        var spots: [SpotFromCloud] = []
        var predicate = NSPredicate()
        if radiusInMeters == 0 {
            predicate = NSPredicate(value: true)
        } else {
            predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", userLocation, CGFloat(radiusInMeters))
        }
        let secondPredicate = NSPredicate(format: "userID != %@", self.userID)
        let compundPred = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, secondPredicate])
        var query = CKQuery(recordType: "Spots", predicate: compundPred)
        if !search.isEmpty {
            let predicate2 = NSPredicate(format: "self contains %@", search)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2, secondPredicate])
            query = CKQuery(recordType: "Spots", predicate: compoundPredicate)
        }
        if filteringBy == "Closest".localized() {
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [distance, creation]
        } else if filteringBy == "Downloads".localized() {
            let likes = NSSortDescriptor(key: "likes", ascending: false)
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [likes, distance, creation]
        } else if filteringBy == "Name".localized() {
            let name = NSSortDescriptor(key: "name", ascending: true)
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [name, distance, creation]
        } else if filteringBy == "Newest".localized() {
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [creation, distance]
        }
        
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: desiredKeys, resultsLimit: limit)
        DispatchQueue.main.async {
            self.cursorMain = nil
        }
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                    guard let name = record["name"] as? String else { return }
                    guard let founder = record["founder"] as? String else { return }
                    guard let date = record["date"] as? String else { return }
                    var dateObject: Date?
                    if let dateObj = record["dateObject"] as? Date {
                        dateObject = dateObj
                    } else {
                        dateObject = nil
                    }
                    guard let location = record["location"] as? CLLocation else { return }
                    guard let likes = record["likes"] as? Int else { return }
                    guard let id = record["id"] as? String else { return }
                    guard let user = record["userID"] as? String else { return }
                    var customLocation = 0
                    if let customLocationChecked = record["customLocation"] as? Int {
                        customLocation = customLocationChecked
                    }
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
                    spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: nil,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record))
            case .failure(let error):
                print("\(error)")
                DispatchQueue.main.async {
                    self.isFetching = false
                }
                return
            }
        }
        
        DispatchQueue.main.async {
            self.isFetching = false
            self.cursorMain = results.queryCursor
        }
        return spots
    }
    
    func updateSpotPublic(id: String, newName: String, newDescription: String, newFounder: String, newType: String, imageChanged: Bool, image: Data?, image2: Data?, image3: Data?, isMultipleImages: Int) async throws -> Bool {
        if id.isEmpty {
            return false
        }
        let recordID = CKRecord.ID(recordName: id)
        let record = try await CKContainer.default().publicCloudDatabase.record(for: recordID)
        record["name"] = newName
        record["description"] = newDescription
        record["type"] = newType
        record["founder"] = newFounder
        record["isMultipleImages"] = isMultipleImages
        if (imageChanged) {
            if let image3 = image3 {
                do {
                    let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                    let url = URL(fileURLWithPath: path)
                    try image3.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    record["image3"] = asset
                } catch {
                    print(error)
                    return false
                }
            } else {
                record["image3"] = nil
            }
            
            if let image2 = image2 {
                do {
                    let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                    let url = URL(fileURLWithPath: path)
                    try image2.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    record["image2"] = asset
                } catch {
                    print(error)
                    return false
                }
            } else {
                record["image2"] = nil
                record["image3"] = nil
            }
            
            if let image = image {
                do {
                    let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
                    let url = URL(fileURLWithPath: path)
                    try image.write(to: url)
                    let asset = CKAsset(fileURL: url)
                    record["image"] = asset
                } catch {
                    print(error)
                    return false
                }
            }
        }
        
        try await CKContainer.default().publicCloudDatabase.save(record)
        return true
    }
    
    func likeSpot(spot: SpotFromCloud) async -> Bool {
        guard let _ = spot.record["likes"] else { return false }
        let record = spot.record
        record["likes"]! += 1
        do {
            try await CKContainer.default().publicCloudDatabase.save(record)
            return true
        } catch {
            return false
        }
    }
    
    func addDownloads(spot: SpotFromCloud) async {
        guard let _ = spot.record["likes"] else { return }
        let record = spot.record
        record["likes"]! += Int.random(in: 8...24)
        do {
            try await CKContainer.default().publicCloudDatabase.save(record)
        } catch {
            print("error adding downloads")
        }
    }
    
    func report(spot: SpotFromCloud, report: String) async {
        guard let _ = spot.record[report] else { return }
        let record = spot.record
        record[report]! += 1
        do {
            try await CKContainer.default().publicCloudDatabase.save(record)
        } catch {
            print("failed to send report!")
        }
    }
    
    func fetchMoreSpotsPublic(cursor: CKQueryOperation.Cursor, desiredKeys: [String], resultLimit: Int) async -> [SpotFromCloud] {
        var spots: [SpotFromCloud] = []
        DispatchQueue.main.async {
            self.isFetching = true
        }
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(continuingMatchFrom: cursor, desiredKeys: desiredKeys, resultsLimit: resultLimit)
            results.matchResults.forEach { (_,result) in
                switch result {
                case .success(let record):
                        guard let name = record["name"] as? String else { return }
                        guard let founder = record["founder"] as? String else { return }
                        guard let date = record["date"] as? String else { return }
                        var dateObject: Date?
                        if let dateObj = record["dateObject"] as? Date {
                            dateObject = dateObj
                        } else {
                            dateObject = nil
                        }
                        guard let location = record["location"] as? CLLocation else { return }
                        guard let likes = record["likes"] as? Int else { return }
                        guard let id = record["id"] as? String else { return }
                        guard let user = record["userID"] as? String else { return }
                        var customLocation = 0
                        if let customLocationChecked = record["customLocation"] as? Int {
                            customLocation = customLocationChecked
                        }
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
                        spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: nil,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record))
                    
                case .failure(let error):
                    print("\(error)")
                    DispatchQueue.main.async {
                        self.isFetching = false
                    }
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.isFetching = false
                self.cursorMain = results.queryCursor
            }
        } catch {
            DispatchQueue.main.async {
                self.isFetching = false
                self.isErrorMessage = "Unable To Load More Spots"
                self.isErrorMessageDetails = "Check internet conection and try again."
                self.isError.toggle()
            }
        }
        return spots
    }
    
    // MARK: - Other
    
    func compressImage(image: UIImage) -> UIImage {
        let resizedImage = image.aspectFittedToHeight(200)
        resizedImage.jpegData(compressionQuality: 1.0)
        
        return resizedImage
    }
    
    func isBanned() async throws -> Bool {
        let predicate = NSPredicate(format: "userid == %@", userID)
        let query = CKQuery(recordType: "Bans", predicate: predicate)
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, resultsLimit: 1)
        if results.matchResults.isEmpty {
            UserDefaults.standard.set(false, forKey: "isBanned")
            return false
        } else {
            UserDefaults.standard.set(true, forKey: "isBanned")
            return true
        }
    }
    
    func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self?.accountStatus = .couldNotDetermine
                    self?.isSignedInToiCloud = false
                case .available:
                    self?.isSignedInToiCloud = true
                    self?.fetchUserID()
                case .restricted:
                    self?.accountStatus = .restricted
                    self?.isSignedInToiCloud = false
                case .noAccount:
                    self?.accountStatus = .noAccount
                    self?.isSignedInToiCloud = false
                case .temporarilyUnavailable:
                    self?.accountStatus = .temporarilyUnavailable
                    self?.isSignedInToiCloud = false
                @unknown default:
                    self?.accountStatus = nil
                    self?.isSignedInToiCloud = false
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
    
    func isMySpot(user: String) -> Bool {
        if userID == user {
            return true
        }
        return false
    }
    
    private func setUserDefaults() {
        if let id = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") {
            userID = id
        }
        if (UserDefaults.standard.valueExists(forKey: "limit")) {
            limit = UserDefaults.standard.integer(forKey: "limit")
        } else {
            UserDefaults.standard.set(10, forKey: "limit")
        }
        if (UserDefaults.standard.valueExists(forKey: "discovernot")) {
            notiNewSpotOn = UserDefaults.standard.bool(forKey: "discovernot")
        } else {
            UserDefaults.standard.set(false, forKey: "discovernot")
        }
        if (UserDefaults.standard.valueExists(forKey: "sharednot")) {
            notiSharedOn = UserDefaults.standard.bool(forKey: "sharednot")
        } else {
            UserDefaults.standard.set(false, forKey: "sharednot")
        }
        setColors()
    }
    
    private func setColors() {
        if let i = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") {
            systemColorIndex = i
        }
        if UserDefaults.standard.valueExists(forKey: "customColorA") {
            let green = UserDefaults.standard.double(forKey: "customColorG")
            let blue = UserDefaults.standard.double(forKey: "customColorB")
            let red = UserDefaults.standard.double(forKey: "customColorR")
            let alpha = UserDefaults.standard.double(forKey: "customColorA")
            systemColorArray[systemColorIndex] = Color(uiColor: UIColor(red: red, green: green, blue: blue, alpha: alpha))
        }
    }
    
    // MARK: - Notifications
    
    func resetBadgeNewSpots() {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: UserDefaults.standard.integer(forKey: "badgeplaylists"))
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print(error as Any)
            }
        }
        CKContainer.default().add(badgeResetOperation)
    }
    
    func resetBadgePlaylists() {
        let badgeResetOperation = CKModifyBadgeOperation(badgeValue: UserDefaults.standard.integer(forKey: "badge"))
        badgeResetOperation.modifyBadgeCompletionBlock = { (error) -> Void in
            if error != nil {
                print(error as Any)
            }
        }
        CKContainer.default().add(badgeResetOperation)
    }
    
    func checkNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            DispatchQueue.main.async {
                self.notiPermission = 0
            }
        case .denied:
            DispatchQueue.main.async {
                self.notiPermission = 1
            }
        case .authorized:
            DispatchQueue.main.async {
                self.notiPermission = 2
            }
        case .provisional:
            DispatchQueue.main.async {
                self.notiPermission = 3
            }
        case .ephemeral:
            DispatchQueue.main.async {
                self.notiPermission = 4
            }
        @unknown default:
            DispatchQueue.main.async {
                self.notiPermission = 5
            }
        }
    }
    
    func requestPermissionNoti() async {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        do {
            let success = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            if success {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.notiPermission = 2
                }
            } else {
                DispatchQueue.main.async {
                    self.notiPermission = 1
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.notiPermission = 1
            }
        }
    }
    
    func unsubscribeAllPublic() async throws {
        let subs = try await CKContainer.default().publicCloudDatabase.allSubscriptions()
        for sub in subs {
            _ = try await CKContainer.default().publicCloudDatabase.deleteSubscription(withID: sub.subscriptionID)
        }
    }
    
    func unsubscribeAllShared() async throws {
        let subs = try await CKContainer.default().sharedCloudDatabase.allSubscriptions()
        for sub in subs {
            _ = try await CKContainer.default().sharedCloudDatabase.deleteSubscription(withID: sub.subscriptionID)
        }
    }
    
    func unsubscribeAllPrivate() async throws {
        let subs = try await CKContainer.default().privateCloudDatabase.allSubscriptions()
        for sub in subs {
            _ = try await CKContainer.default().privateCloudDatabase.deleteSubscription(withID: sub.subscriptionID)
        }
    }
    
    func subscribeToNewSpot(fixedLocation: CLLocation) async throws {
        try? await unsubscribeAllPublic()
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", fixedLocation, CGFloat(16093.4))
        let subscription = CKQuerySubscription(recordType: "Spots", predicate: predicate, options: .firesOnRecordCreation)
        let notification = CKSubscription.NotificationInfo()
        notification.alertLocalizationKey = "%1$@ was added to your area!"
        notification.alertLocalizationArgs = ["name"]
        notification.title = "My Spot"
        notification.alertBody = "%1$@ was added to your area!"
        notification.soundName = "default"
        notification.shouldBadge = true
        notification.desiredKeys = ["id"]
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        try await CKContainer.default().publicCloudDatabase.save(subscription)
    }
    
    func subscribeToShares() async throws {
        try? await unsubscribeAllShared()
        try? await unsubscribeAllPrivate()
        let subscription = CKDatabaseSubscription(subscriptionID: UUID().uuidString)
        let notification = CKSubscription.NotificationInfo()
        subscription.recordType = "cloudkit.share"
        notification.title = "My Spot"
        notification.alertBody = "Your friend's playlist has been modified.".localized()
        notification.soundName = "default"
        notification.shouldBadge = false
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        try await CKContainer.default().sharedCloudDatabase.save(subscription)
        let subscriptionPrivate = CKDatabaseSubscription(subscriptionID: UUID().uuidString)
        let notificationPrivate = CKSubscription.NotificationInfo()
        subscriptionPrivate.recordType = "cloudkit.share"
        notificationPrivate.title = "My Spot"
        notificationPrivate.alertBody = "Your shared playlist has been modified.".localized()
        notificationPrivate.soundName = "default"
        notificationPrivate.shouldBadge = false
        notificationPrivate.shouldSendContentAvailable = true
        subscriptionPrivate.notificationInfo = notificationPrivate
        try await CKContainer.default().privateCloudDatabase.save(subscriptionPrivate)
    }
    
    // MARK: - Account
    
    func addNewAccount(userid: String, name: String, pronoun: String, image: Data, bio: String, email: String, youtube: String, tiktok: String, insta: String) async throws {
        let newAccount = CKRecord(recordType: "Accounts")
        newAccount["userid"] = userid
        newAccount["name"] = name
        newAccount["bio"] = bio
        newAccount["youtube"] = youtube
        newAccount["tiktok"] = tiktok
        newAccount["instagram"] = insta
        newAccount["email"] = email
        newAccount["isExplorer"] = false
        newAccount["pronoun"] = pronoun
        let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
        let url = URL(fileURLWithPath: path)
        try image.write(to: url)
        let asset = CKAsset(fileURL: url)
        newAccount["image"] = asset
        try await CKContainer.default().publicCloudDatabase.save(newAccount)
    }
    
    func doesAccountExist(for userid: String) async -> Bool {
        let predicate = NSPredicate(format: "userid == %@", userid)
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, resultsLimit: 1)
            if results.matchResults.isEmpty {
                return false
            } else {
                results.matchResults.forEach { (_,result) in
                    switch result {
                    case .success(let record):
                        if let name = record["name"] {
                            UserDefaults.standard.set(name, forKey: "founder")
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                return true
            }
        } catch {
            return true
        }
    }
    
    func getDownloadsAndSpots(from userid: String) async throws -> [Int] {
        let predicate = NSPredicate(format: "userID == %@", userid)
        let query = CKQuery(recordType: "Spots", predicate: predicate)
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: ["userID", "likes"])
        var downloads = 0
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                guard let download = record["likes"] as? Int else { return }
                downloads += download
            case .failure(let error):
                print(error)
            }
        }
        return [downloads, results.matchResults.count]
    }
    
    func getMemberSince(fromid userid: String) async throws {
        let predicate = NSPredicate(format: "userid == %@", userid)
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: ["userid"])
        var date: Date?
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                if let dateFetched = record.creationDate {
                    date = dateFetched
                }
            case .failure(let error):
                print(error)
            }
        }
        UserDefaults.standard.set(date, forKey: "accountdate")
    }
    
    func makeExplorer(id: CKRecord.ID) async throws {
        let record = try await CKContainer.default().publicCloudDatabase.record(for: id)
        record["isExplorer"] = true
        try await CKContainer.default().publicCloudDatabase.save(record)
    }
    
    func updateAccount(id: CKRecord.ID, newName: String, newBio: String?, newPronouns: String?, newEmail: String?, newTiktok: String?, image: Data?, newInsta: String?, newYoutube: String?) async throws {
        let record = try await CKContainer.default().publicCloudDatabase.record(for: id)
        record["name"] = newName
        if let newBio = newBio {
            record["bio"] = newBio
        }
        if let newEmail = newEmail {
            record["email"] = newEmail
        }
        if let newPronouns = newPronouns {
            record["pronoun"] = newPronouns
        }
        if let newTiktok = newTiktok {
            record["tiktok"] = newTiktok
        }
        if let newInsta = newInsta {
            record["instagram"] = newInsta
        }
        if let newYoutube = newYoutube {
            record["youtube"] = newYoutube
        }
        if let image = image {
            let path = NSTemporaryDirectory() + "imageTemp\(UUID().uuidString).png"
            let url = URL(fileURLWithPath: path)
            try image.write(to: url)
            let asset = CKAsset(fileURL: url)
            record["image"] = asset
        }
        try await CKContainer.default().publicCloudDatabase.save(record)
    }
    
    func fetchAccountSpots(userid: String) async throws -> [SpotFromCloud] {
        let predicate = NSPredicate(format: "userID == %@", userid)
        let query = CKQuery(recordType: "Spots", predicate: predicate)
        let creation = NSSortDescriptor(key: "creationDate", ascending: false)
        var spots: [SpotFromCloud] = []
        query.sortDescriptors = [creation]
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: desiredKeys, resultsLimit: limit)
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                var dateObject: Date?
                if let dateObj = record["dateObject"] as? Date {
                    dateObject = dateObj
                } else {
                    dateObject = nil
                }
                guard let location = record["location"] as? CLLocation else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                var customLocation = 0
                if let customLocationChecked = record["customLocation"] as? Int {
                    customLocation = customLocationChecked
                }
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
                spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: nil,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record))
                
            case .failure(let error):
                print("\(error)")
                return
            }
        }
        DispatchQueue.main.async {
            self.cursorAccount = results.queryCursor
        }
        return spots
    }
    
    func fetchMoreAccountSpots(cursor: CKQueryOperation.Cursor) async throws -> [SpotFromCloud] {
        DispatchQueue.main.async {
            self.cursorAccount = nil
        }
        let results = try await CKContainer.default().publicCloudDatabase.records(continuingMatchFrom: cursor, desiredKeys: desiredKeys, resultsLimit: limit)
        var spots: [SpotFromCloud] = []
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let founder = record["founder"] as? String else { return }
                guard let date = record["date"] as? String else { return }
                var dateObject: Date?
                if let dateObj = record["dateObject"] as? Date {
                    dateObject = dateObj
                } else {
                    dateObject = nil
                }
                guard let location = record["location"] as? CLLocation else { return }
                guard let likes = record["likes"] as? Int else { return }
                guard let id = record["id"] as? String else { return }
                guard let user = record["userID"] as? String else { return }
                var customLocation = 0
                if let customLocationChecked = record["customLocation"] as? Int {
                    customLocation = customLocationChecked
                }
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
                spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: nil,  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, customLocation: customLocation, locationName: locationName, userID: user, dateObject: dateObject, record: record))
                
            case .failure(let error):
                print(error)
            }
        }
        DispatchQueue.main.async {
            self.cursorAccount = results.queryCursor
        }
        return spots
    }
    
    func fetchAccount(userid: String, withImage: Bool? = false) async throws -> AccountModel? {
        let predicate = NSPredicate(format: "userid == %@", userid)
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        var keys = userKeys
        if withImage ?? false {
            keys.append("image")
        }
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: keys, resultsLimit: 1)
        var user: AccountModel?
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                var image: UIImage?
                if let imageAsset = record["image"] as? CKAsset {
                    guard let imageURL = imageAsset.fileURL else { return }
                    guard let imageData = NSData(contentsOf: imageURL) as? Data else { return }
                    guard let imageFromCloud = UIImage(data: imageData) else { return }
                    image = imageFromCloud
                }
                guard let id = record["userid"] as? String else { return }
                guard let name = record["name"] as? String else { return }
                guard let isExplorerBinary = record["isExplorer"] as? Int else { return }
                let pronouns = record["pronoun"] as? String
                let bio = record["bio"] as? String
                let tiktok = record["tiktok"] as? String
                let youtube = record["youtube"] as? String
                let insta = record["instagram"] as? String
                let email = record["email"] as? String
                user = AccountModel(id: id, name: name, image: image, pronouns: pronouns, isExplorer: (isExplorerBinary == 0 ? false : true), bio: bio, record: record, tiktok: tiktok, insta: insta, youtube: youtube, email: email)
            case .failure(let error):
                print(error)
            }
        }
        return user
    }
    
    func fetchAccounts(searchText: String) async -> [AccountModel] {
        var users: [AccountModel] = []
        let predicate = NSPredicate(format: "userid != %@", self.userID)
        var query = CKQuery(recordType: "Accounts", predicate: predicate)
        if !searchText.isEmpty {
            let predicate2 = NSPredicate(format: "self contains %@", searchText)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
            query = CKQuery(recordType: "Accounts", predicate: compoundPredicate)
        }
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        DispatchQueue.main.async {
            self.cursorUsers = nil
        }
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: userKeys, resultsLimit: limit)
            results.matchResults.forEach { (_,result) in
                switch result {
                case .success(let record):
                    guard let id = record["userid"] as? String else { return }
                    guard let name = record["name"] as? String else { return }
                    guard let isExplorerBinary = record["isExplorer"] as? Int else { return }
                    let pronouns = record["pronoun"] as? String
                    let bio = record["bio"] as? String
                    let tiktok = record["tiktok"] as? String
                    let youtube = record["youtube"] as? String
                    let insta = record["instagram"] as? String
                    let email = record["email"] as? String
                    users.append(AccountModel(id: id, name: name, image: nil, pronouns: pronouns, isExplorer: (isExplorerBinary == 0 ? false : true), bio: bio, record: record, tiktok: tiktok, insta: insta, youtube: youtube, email: email))
                case .failure(let error):
                    print(error)
                }
            }
            DispatchQueue.main.async {
                self.cursorUsers = results.queryCursor
            }
        } catch {
            return users
        }
        return users
    }
    
    func fetchMoreAccounts(cursor: CKQueryOperation.Cursor) async -> [AccountModel] {
        var users: [AccountModel] = []
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(continuingMatchFrom: cursor, desiredKeys: userKeys, resultsLimit: limit)
            results.matchResults.forEach { (_,result) in
                switch result {
                case .success(let record):
                    guard let id = record["userid"] as? String else { return }
                    guard let name = record["name"] as? String else { return }
                    guard let isExplorerBinary = record["isExplorer"] as? Int else { return }
                    let pronouns = record["pronoun"] as? String
                    let bio = record["bio"] as? String
                    let tiktok = record["tiktok"] as? String
                    let youtube = record["youtube"] as? String
                    let insta = record["instagram"] as? String
                    let email = record["email"] as? String
                    users.append(AccountModel(id: id, name: name, image: nil, pronouns: pronouns, isExplorer: (isExplorerBinary == 0 ? false : true), bio: bio, record: record, tiktok: tiktok, insta: insta, youtube: youtube, email: email))
                case .failure(let error):
                    print(error)
                }
            }
            DispatchQueue.main.async {
                self.cursorUsers = results.queryCursor
            }
        } catch {
            return users
        }
        return users
    }
    
    func fetchAccountImage(userid: String) async -> UIImage? {
        var image: UIImage?
        let predicate = NSPredicate(format: "userid == %@", userid)
        let query = CKQuery(recordType: "Accounts", predicate: predicate)
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: ["image"], resultsLimit: 1)
            results.matchResults.forEach { (_,result) in
                switch result {
                case .success(let record):
                    guard let imageAsset = record["image"] as? CKAsset else { return }
                    guard let imageURL = imageAsset.fileURL else { return }
                    guard let imageData = NSData(contentsOf: imageURL) as? Data else { return }
                    guard let imageFromCloud = UIImage(data: imageData) else { return }
                    image = imageFromCloud
                case .failure(let error):
                    print(error)
                }
            }
        } catch {
            return image
        }
        return image
    }
}
