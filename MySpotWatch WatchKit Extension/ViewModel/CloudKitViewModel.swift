//
//  CloudKitViewModel.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import CloudKit
import SwiftUI

class CloudKitViewModel: ObservableObject {
    let desiredKeys = ["name", "location", "locationName", "customLocation", "image", "userID", "description"]
    
    init() { }
    
    func fetchSpotPublic(userLocation: CLLocation, resultLimit: Int, distance: Double, completion: @escaping (Result<[Spot], Error>) -> ()) {
        var predicate = NSPredicate(value: true)
        if distance != 0 {
            predicate = NSPredicate(format: "distanceToLocation:fromLocation:(location, %@) < %f", userLocation, CGFloat(distance))
        }
        let query = CKQuery(recordType: "Spots", predicate: predicate)
        let distance = CKLocationSortDescriptor(key: "location", relativeLocation: userLocation)
        let creation = NSSortDescriptor(key: "creationDate", ascending: false)
        query.sortDescriptors = [distance, creation]
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = resultLimit
        var returnedSpots: [Spot] = []
        queryOperation.recordMatchedBlock = { (recordID, result) in
            switch result {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                guard let image = record["image"] as? CKAsset else { return }
                var customLocation = 0
                if let customLocationChecked = record["customLocation"] as? Int {
                    customLocation = customLocationChecked
                }
                var isCustomLocation = false
                if customLocation == 0 {
                    isCustomLocation = true
                }
                var locationName = ""
                if let locationNameCheck = record["locationName"] as? String {
                    locationName = locationNameCheck
                }
                var description = ""
                if let descriptionCheck = record["description"] as? String {
                    description = descriptionCheck
                }
                guard let imageData = try? Data(contentsOf: image.fileURL!) else { return }
                guard let location = record["location"] as? CLLocation else { return }
                let x = location.coordinate.latitude
                let y = location.coordinate.longitude
                returnedSpots.append(Spot(spotid: record.recordID.recordName,name: name, customLocation: isCustomLocation, locationName: locationName, image: imageData, x: x, y: y, description: description))
            case .failure(let error):
                print("\(error)")
                completion(.failure(error))
            }
        }
        queryOperation.queryResultBlock = { result in
            print("returned result: \(result)")
            completion(.success(returnedSpots))
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKDatabaseOperation) {
        CKContainer(identifier: "iCloud.com.isaacpaschall.My-Spot").publicCloudDatabase.add(operation)
    }
}
