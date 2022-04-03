//
//  CloudKitViewModel.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import SwiftUI
import CloudKit

class CloudKitViewModel: ObservableObject {
    
    @Published var totalMapSize = 2
    @Published var notiPlaylistOn = false
    @Published var notiNewSpotOn = false
    @Published var systemColorIndex = 0
    @Published var systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow, .gray]
    @Published var isSignedInToiCloud: Bool = false
    @Published var error: String = ""
    @Published var spots: [SpotFromCloud] = []
    @Published var shared: [SpotFromCloud] = []
    @Published var userID: String = ""
    @Published var canRefresh = false
    @Published var isFetching = false
    @Published var isError = false
    @Published var isErrorMessage = ""
    @Published var isErrorMessageDetails = ""
    @Published var isPostError = false
    @Published var radiusInMeters: Double = 0
    @Published var notiPermission = 0 // 0: not determined, 1: denied, 2: allowed, 3: provisional, 4: ephemeral, 5: unknown
    @Published var cursorMain: CKQueryOperation.Cursor?
    @Published var desiredKeys = ["name", "founder", "date", "location", "likes", "inappropriate", "offensive", "dangerous", "spam", "id", "userID", "image", "type", "isMultipleImages", "locationName", "description"]
    
    init() {
        getiCloudStatus()
        setUserDefaults()
    }
    
    private func setUserDefaults() {
        if (UserDefaults.standard.valueExists(forKey: "savedDistance")) {
            radiusInMeters = Double(UserDefaults.standard.integer(forKey: "savedDistance"))
        }
        if (UserDefaults.standard.valueExists(forKey: "discovernot")) {
            notiNewSpotOn = UserDefaults.standard.bool(forKey: "discovernot")
        } else {
            UserDefaults.standard.set(false, forKey: "discovernot")
        }
        if (UserDefaults.standard.valueExists(forKey: "playlistnot")) {
            notiPlaylistOn = UserDefaults.standard.bool(forKey: "playlistnot")
        } else {
            UserDefaults.standard.set(false, forKey: "playlistnot")
        }
        if UserDefaults.standard.valueExists(forKey: "customColorA") {
            systemColorArray[systemColorArray.count - 1] = Color(uiColor: UIColor(red: UserDefaults.standard.double(forKey: "customColorR"), green: UserDefaults.standard.double(forKey: "customColorG"), blue: UserDefaults.standard.double(forKey: "customColorB"), alpha: UserDefaults.standard.double(forKey: "customColorA")))
        }
    }
    
    func deleteSpot(id: CKRecord.ID) async throws {
        try await CKContainer.default().publicCloudDatabase.deleteRecord(withID: id)
    }
    
    func checkDeepLink(url: URL) async {
        guard let host = URLComponents(url: url, resolvingAgainstBaseURL: true)?.host else {
            isErrorMessage = "Invalid Link"
            isErrorMessageDetails = "Check that the link was not modified and try again."
            isError.toggle()
            return
        }
        do {
            let record = try await CKContainer.default().publicCloudDatabase.record(for: CKRecord.ID(recordName: host))
            DispatchQueue.main.async {
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
            }
        } catch {
            DispatchQueue.main.async {
                self.isErrorMessage = "Unable To Find Spot"
                self.isErrorMessageDetails = "This is due to poor internet connection or the spot you are looking for has been deleted by the founder."
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
    
    func addSpotToPublic(name: String, founder: String, date: String, locationName: String, x: Double, y: Double, description: String, type: String, image: Data, image2: Data?, image3: Data?, isMultipleImages: Int) async throws -> String {
        
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
    
    func fetchSpotPublic(userLocation: CLLocation, filteringBy: String, search: String) async throws {
        self.isFetching = true
        var predicate = NSPredicate()
        if radiusInMeters == 0 {
            predicate = NSPredicate(value: true)
        } else {
            predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", userLocation, CGFloat(radiusInMeters))
        }
        var query = CKQuery(recordType: "Spots", predicate: predicate)
        if !search.isEmpty {
            let predicate2 = NSPredicate(format: "self contains %@", search)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
            query = CKQuery(recordType: "Spots", predicate: compoundPredicate)
        }
        if filteringBy == "Closest" {
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [distance, creation]
        } else if filteringBy == "Likes" {
            let likes = NSSortDescriptor(key: "likes", ascending: false)
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [likes, distance, creation]
        } else if filteringBy == "Name" {
            let name = NSSortDescriptor(key: "name", ascending: true)
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [name, distance, creation]
        } else if filteringBy == "Newest" {
            let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
            let creation = NSSortDescriptor(key: "creationDate", ascending: false)
            query.sortDescriptors = [creation, distance]
        }
        
        let results = try await CKContainer.default().publicCloudDatabase.records(matching: query, desiredKeys: desiredKeys, resultsLimit: 20)
        DispatchQueue.main.async {
            self.spots.removeAll()
            self.cursorMain = nil
        }
        results.matchResults.forEach { (_,result) in
            switch result {
            case .success(let record):
                DispatchQueue.main.async {
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
                    self.spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record))
                }
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
        }
        
        if let cursor = results.queryCursor {
            DispatchQueue.main.async {
                self.cursorMain = cursor
            }
        }
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
    
    func fetchMoreSpotsPublic(cursor: CKQueryOperation.Cursor, desiredKeys: [String], resultLimit: Int) async {
        self.isFetching = true
        self.cursorMain = nil
        do {
            let results = try await CKContainer.default().publicCloudDatabase.records(continuingMatchFrom: cursor, desiredKeys: desiredKeys, resultsLimit: resultLimit)
            results.matchResults.forEach { (_,result) in
                switch result {
                case .success(let record):
                    DispatchQueue.main.async {
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
                        self.spots.append(SpotFromCloud(id: id, name: name, founder: founder, description: description, date: date, location: location, type: types, imageURL: imageURL ?? URL(fileURLWithPath: "none"),  image2URL: nil , image3URL: nil, isMultipleImages: isMultipleImages , likes: likes, offensive: offensive, spam: spam, inappropriate: inappropriate, dangerous: dangerous, locationName: locationName, userID: user, record: record))
                    }
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
            }
            
            if let cursor = results.queryCursor {
                DispatchQueue.main.async {
                    self.cursorMain = cursor
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isFetching = false
                self.cursorMain = nil
                self.isErrorMessage = "Unable To Load More Spots"
                self.isErrorMessageDetails = "Check internet conection and try again."
                self.isError.toggle()
            }
        }
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
                await UIApplication.shared.registerForRemoteNotifications()
                DispatchQueue.main.async {
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
    
    func unsubscribe(id: CKSubscription.ID) async throws {
        _ = try await CKContainer.default().publicCloudDatabase.deleteSubscription(withID: id)
    }
    
    func subscribeToNewSpot(fixedLocation: CLLocation, radiusInKm: CGFloat, filters: [String]) async throws {
        let predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", fixedLocation, radiusInKm)
        var subscription = CKQuerySubscription(recordType: "Spots", predicate: predicate, subscriptionID: "NewSpotDiscover", options: .firesOnRecordCreation)
        if !filters.isEmpty {
            var compoundPredicate = NSCompoundPredicate()
            if filters.count == 1 {
                let predicate2 = NSPredicate(format: "self contains %@", filters[0])
                compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, predicate2])
            } else if filters.count == 2 {
                let predicate2 = NSPredicate(format: "self contains %@", filters[0])
                let predicate3 = NSPredicate(format: "self contains %@", filters[1])
                let compundOr = NSCompoundPredicate(type: .or, subpredicates: [predicate2, predicate3])
                compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, compundOr])
            } else if filters.count == 3 {
                let predicate2 = NSPredicate(format: "self contains %@", filters[0])
                let predicate3 = NSPredicate(format: "self contains %@", filters[1])
                let predicate4 = NSPredicate(format: "self contains %@", filters[2])
                let compundOr = NSCompoundPredicate(type: .or, subpredicates: [predicate2, predicate3, predicate4])
                compoundPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicate, compundOr])
            }
            subscription = CKQuerySubscription(recordType: "Spots", predicate: compoundPredicate, subscriptionID: "NewSpotDiscover", options: .firesOnRecordCreation)
        }
        let notification = CKSubscription.NotificationInfo()
        notification.title = "My Spot"
        notification.alertBody = "A new spot was added to your area!"
        notification.soundName = "default"
        notification.shouldBadge = true
        notification.desiredKeys = ["id"]
        subscription.notificationInfo = notification
        try await CKContainer.default().publicCloudDatabase.save(subscription)
    }
    
    private func subscribeToSharedPlaylist() {
        
    }
}
