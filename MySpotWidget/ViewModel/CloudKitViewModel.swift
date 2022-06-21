//
//  CloudKitViewModel.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import CloudKit

final class CloudKitViewModel: ObservableObject {
    
    let desiredKeys = ["name", "location", "locationName", "customLocation", "image", "userID"]
    
    init() { }
    
    func fetchSpotPublic(userLocation: CLLocation, resultLimit: Int, completion: @escaping (Result<[Spot], Error>) -> ()) {
        var predicate = NSPredicate(value: true)
        if let userid = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") {
            predicate = NSPredicate(format: "userID != %@", userid)
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
                guard let imageData = try? Data(contentsOf: image.fileURL!) else { return }
                guard let location = record["location"] as? CLLocation else { return }
                let x = location.coordinate.latitude
                let y = location.coordinate.longitude
                returnedSpots.append(Spot(spotid: record.recordID.recordName,name: name, customLocation: isCustomLocation, locationName: locationName, image: imageData, x: x, y: y))
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
