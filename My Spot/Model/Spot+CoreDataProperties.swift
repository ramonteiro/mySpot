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
import CoreLocation


extension Spot {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Spot> {
        return NSFetchRequest<Spot>(entityName: "Spot")
    }

    @NSManaged public var details: String?
    @NSManaged public var dateObject: Date?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var addedBy: String?
    @NSManaged public var isShared: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var image: UIImage?
    @NSManaged public var image2: UIImage?
    @NSManaged public var image3: UIImage?
    @NSManaged public var likes: Double
    @NSManaged public var name: String?
    @NSManaged public var userId: String?
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var isPublic: Bool
    @NSManaged public var wasThere: Bool
    @NSManaged public var fromDB: Bool
    @NSManaged public var date: String?
    @NSManaged public var founder: String?
    @NSManaged public var tags: String?
    @NSManaged public var dbid: String?
    @NSManaged public var locationName: String?
    @NSManaged public var playlist: Playlist?
    
    public var wrappedName: String {
        name ?? "Unknown Name"
    }

}

extension Spot: Identifiable { }

extension Spot: SpotPreviewType {
    
    var addedByPreview: String? {
        addedBy
    }
    
    var descriptionPreview: String {
        description
    }
    
    var locationPreview: CLLocation {
        CLLocation(latitude: x, longitude: y)
    }
    
    var isMultipleImagesPreview: Bool {
        image2 != nil
    }
    
    var dateAddedToPlaylistPreview: Date? {
        dateAdded
    }
    
    var userIDPreview: String {
        userId ?? ""
    }
    
    var playlistPreview: Playlist? {
        playlist
    }
    
    var isFromDiscover: Bool {
        false
    }
    
    var namePreview: String {
        name ?? ""
    }
    
    var founderPreview: String {
        founder ?? ""
    }
    
    var datePreview: String {
        date ?? ""
    }
    
    var dateObjectPreview: Date? {
        dateObject
    }
    
    var imagePreview: UIImage? {
        image
    }
    
    var locationNamePreview: String {
        locationName ?? ""
    }
    
    var customLocationPreview: Bool {
        !wasThere
    }
    
    var tagsPreview: String {
        tags ?? ""
    }
    
    var isPublicPreview: Bool {
        isPublic
    }
    
    var downloadsPreview: Int {
        Int(likes)
    }
}
