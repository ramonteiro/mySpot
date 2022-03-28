//
//  Likes+CoreDataProperties.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/12/22.
//
//

import Foundation
import CoreData


extension Likes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Likes> {
        return NSFetchRequest<Likes>(entityName: "Likes")
    }

    @NSManaged public var likedId: String?
    @NSManaged public var reportId: String?

}

extension Likes : Identifiable {

}
