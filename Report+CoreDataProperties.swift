//
//  Report+CoreDataProperties.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/31/22.
//
//

import Foundation
import CoreData


extension Report {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Report> {
        return NSFetchRequest<Report>(entityName: "Report")
    }

    @NSManaged public var reportid: String?

}

extension Report : Identifiable {

}
