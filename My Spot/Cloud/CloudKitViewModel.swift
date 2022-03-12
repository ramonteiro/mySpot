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
    
    init() {
        getiCloudStatus()
    }
    
    func getiCloudStatus() {
        CKContainer.default().accountStatus { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .couldNotDetermine:
                    self?.error = CloudKitError.iCloudAccountNotDetermined.rawValue
                case .available:
                    self?.isSignedInToiCloud = true
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
    
    func addSpotToPublic(name: String, founder: String, date: String, x: Double, y: Double, description: String, type: String, image: UIImage, emoji: String) -> String {
        let newSpot = CKRecord(recordType: "Spots")
        newSpot["name"] = name
        newSpot["founder"] = founder
        newSpot["description"] = description
        newSpot["date"] = date
        newSpot["location"] = CLLocation(latitude: x, longitude: y)
        newSpot["type"] = type
        newSpot["emoji"] = emoji
        newSpot["id"] = UUID().uuidString
        
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
                let imageURL = image.fileURL
                returnedSpots.append(SpotFromCloud(id: UUID(), name: name, founder: founder, description: description, date: date, location: location, type: type, emoji: emoji, imageURL: imageURL ?? URL(fileURLWithPath: "none"), record: record))
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
    
    func fetchMoreSpotsPublic(cursor:CKQueryOperation.Cursor?)  {

        guard let cursorChecked = cursor else { return }
        if spots.count > CloudKitConst.maxLoadTotal {
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
                let imageURL = image.fileURL
                returnedSpots.append(SpotFromCloud(id: UUID(), name: name, founder: founder, description: description, date: date, location: location, type: type, emoji: emoji, imageURL: imageURL ?? URL(fileURLWithPath: "none"), record: record))
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
}
