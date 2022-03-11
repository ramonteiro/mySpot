//
//  Playlist+CoreDataProperties.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/23/22.
//
//

import Foundation
import CoreData


extension Playlist {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Playlist> {
        return NSFetchRequest<Playlist>(entityName: "Playlist")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var emoji: String?
    @NSManaged public var spot: NSSet?
    
    public var wrappedName: String {
        name ?? "Unkown Name"
    }
    
    public var spotArr: [Spot] {
        let set = spot as? Set<Spot> ?? []
        
        return set.sorted {
            $0.wrappedName < $1.wrappedName
        }
    }

}

// MARK: Generated accessors for spot
extension Playlist {

    @objc(addSpotObject:)
    @NSManaged public func addToSpot(_ value: Spot)

    @objc(removeSpotObject:)
    @NSManaged public func removeFromSpot(_ value: Spot)

    @objc(addSpot:)
    @NSManaged public func addToSpot(_ values: NSSet)

    @objc(removeSpot:)
    @NSManaged public func removeFromSpot(_ values: NSSet)

}

extension Playlist : Identifiable {

}
