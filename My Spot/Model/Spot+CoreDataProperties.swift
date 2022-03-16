//
//  Spot+CoreDataProperties.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/23/22.
//
//

import Foundation
import CoreData
import UIKit


extension Spot {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Spot> {
        return NSFetchRequest<Spot>(entityName: "Spot")
    }

    @NSManaged public var details: String?
    @NSManaged public var id: UUID?
    @NSManaged public var image: UIImage?
    @NSManaged public var name: String?
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var isPublic: Bool
    @NSManaged public var date: String?
    @NSManaged public var founder: String?
    @NSManaged public var tags: String?
    @NSManaged public var dbid: String?
    @NSManaged public var emoji: String?
    @NSManaged public var locationName: String?
    @NSManaged public var playlist: Playlist?
    
    public var wrappedName: String {
        name ?? "Unknown Name"
    }

}

extension Spot : Identifiable {

}
