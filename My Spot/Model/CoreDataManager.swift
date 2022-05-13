//
//  CoreDataManager.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

import CoreData
import CloudKit

enum CoreDataErrors: Error {
    case one
    case two
    case three
}

final class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    var recievedShare = false
    var wasSuccessful = false
    
    var ckContainer: CKContainer {
        let storeDescription = persistentContainer.persistentStoreDescriptions.first
        guard let identifier = storeDescription?.cloudKitContainerOptions?.containerIdentifier else {
            fatalError("Unable to get container identifier")
        }
        return CKContainer(identifier: identifier)
    }
    
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var privatePersistentStore: NSPersistentStore {
        guard let privateStore = _privatePersistentStore else {
            fatalError("Private store is not set")
        }
        return privateStore
    }
    
    var sharedPersistentStore: NSPersistentStore {
        guard let sharedStore = _sharedPersistentStore else {
            fatalError("Shared store is not set")
        }
        return sharedStore
    }
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        
        ValueTransformer.setValueTransformer(UIImageTransformer(), forName: NSValueTransformerName("UIImageTransformer"))
        
        let container = NSPersistentCloudKitContainer(name: "Spots")
        
        guard let privateStoreDescription = container.persistentStoreDescriptions.first else {
            fatalError("Unable to get persistentStoreDescription")
        }
        let storesURL = privateStoreDescription.url?.deletingLastPathComponent()
        privateStoreDescription.url = storesURL?.appendingPathComponent("private.sqlite")
        let sharedStoreURL = storesURL?.appendingPathComponent("shared.sqlite")
        guard let sharedStoreDescription = privateStoreDescription.copy() as? NSPersistentStoreDescription else {
            fatalError("Copying the private store description returned an unexpected value.")
        }
        sharedStoreDescription.url = sharedStoreURL
        
        guard let containerIdentifier = privateStoreDescription.cloudKitContainerOptions?.containerIdentifier else {
            fatalError("Unable to get containerIdentifier")
        }
        let sharedStoreOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
        sharedStoreOptions.databaseScope = .shared
        sharedStoreDescription.cloudKitContainerOptions = sharedStoreOptions
        container.persistentStoreDescriptions.append(sharedStoreDescription)
        
        container.loadPersistentStores { loadedStoreDescription, error in
            if let error = error as NSError? {
                fatalError("Failed to load persistent stores: \(error)")
            } else if let cloudKitContainerOptions = loadedStoreDescription.cloudKitContainerOptions {
                guard let loadedStoreDescritionURL = loadedStoreDescription.url else {
                    return
                }
                
                if cloudKitContainerOptions.databaseScope == .private {
                    let privateStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self._privatePersistentStore = privateStore
                } else if cloudKitContainerOptions.databaseScope == .shared {
                    let sharedStore = container.persistentStoreCoordinator.persistentStore(for: loadedStoreDescritionURL)
                    self._sharedPersistentStore = sharedStore
                }
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        do {
            try container.viewContext.setQueryGenerationFrom(.current)
        } catch {
            fatalError("Failed to pin viewContext to the current generation: \(error)")
        }
        
        return container
    }()
    
    private var _privatePersistentStore: NSPersistentStore?
    private var _sharedPersistentStore: NSPersistentStore?
    private init() {}
}

// MARK: Save or delete from Core Data
extension CoreDataStack {
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("ViewContext save error: \(error)")
            }
        }
    }
    
    func delete(_ playlist: Playlist) {
        context.perform {
            self.context.delete(playlist)
            self.save()
        }
    }
    
    func deleteSpot(_ spot: Spot) {
        context.perform {
            self.context.delete(spot)
            self.save()
        }
    }
    
    func deleteSpotsAndPlaylist(_ spot: [Spot], _ playlist: Playlist) {
        context.perform {
            for spot in spot {
                self.context.delete(spot)
            }
            self.context.delete(playlist)
            self.save()
        }
    }
}

// MARK: Share a record from Core Data
extension CoreDataStack {
    
    private func addToShare(_ spots: [NSManagedObject], share: CKShare) async -> CKShare? {
        do {
            let (_, share, _) = try await CoreDataStack.shared.persistentContainer.share(spots, to: share)
            return share
        } catch {
            print("Failed to add to share: \(error)")
            return nil
        }
    }
    
    func addToParentShared(children: [NSManagedObject], parent: NSManagedObject, share: CKShare, userid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            var sharedObjects: [NSManagedObject] = []
            for child in children {
                let spot = child as! Spot
                let newSpot = Spot(context: self.context)
                newSpot.playlist = parent as? Playlist
                newSpot.id = UUID()
                newSpot.isShared = true
                newSpot.date = spot.date
                newSpot.dbid = spot.dbid
                newSpot.details = spot.details
                newSpot.founder = spot.founder
                newSpot.fromDB = spot.fromDB
                newSpot.image = spot.image
                newSpot.image2 = spot.image2
                newSpot.image3 = spot.image3
                newSpot.isPublic = spot.isPublic
                newSpot.likes = spot.likes
                newSpot.locationName = spot.locationName
                newSpot.tags = spot.tags
                newSpot.wasThere = spot.wasThere
                newSpot.x = spot.x
                newSpot.y = spot.y
                newSpot.userId = userid
                newSpot.name = spot.name
                sharedObjects.append(newSpot)
            }
            if let sharedChildren = await addToShare(sharedObjects, share: share) {
                sharedChildren.setParent(share.recordID)
                completion(.success(()))
            } else {
                completion(.failure(CoreDataErrors.two))
            }
        }
    }
    
    func removeFromParent() {
        
    }
    
    func isShared(object: NSManagedObject) -> Bool {
        isShared(objectID: object.objectID)
    }
    
    func canEdit(object: NSManagedObject) -> Bool {
        return persistentContainer.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func canDelete(object: NSManagedObject) -> Bool {
        return persistentContainer.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
    
    func isOwner(object: NSManagedObject) -> Bool {
        guard isShared(object: object) else { return false }
        guard let share = try? persistentContainer.fetchShares(matching: [object.objectID])[object.objectID] else {
            print("Get ckshare error")
            return false
        }
        if let currentUser = share.currentUserParticipant, currentUser == share.owner {
            return true
        }
        return false
    }
    
    func getShare(_ playlist: Playlist) -> CKShare? {
        guard isShared(object: playlist) else { return nil }
        guard let shareDictionary = try? persistentContainer.fetchShares(matching: [playlist.objectID]),
              let share = shareDictionary[playlist.objectID] else {
            print("Unable to get CKShare")
            return nil
        }
        share[CKShare.SystemFieldKey.title] = playlist.name ?? "Shared Playlist"
        share[CKShare.SystemFieldKey.thumbnailImageData] = playlist.emoji?.image()
        return share
    }
    
    
    private func isShared(objectID: NSManagedObjectID) -> Bool {
        var isShared = false
        if let persistentStore = objectID.persistentStore {
            if persistentStore == sharedPersistentStore {
                isShared = true
            } else {
                let container = persistentContainer
                do {
                    let shares = try container.fetchShares(matching: [objectID])
                    if shares.first != nil {
                        isShared = true
                    }
                } catch {
                    print("Failed to fetch share for \(objectID): \(error)")
                }
            }
        }
        return isShared
    }
}
