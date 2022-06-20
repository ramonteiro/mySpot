//
//  SpotFromCloud.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/7/22.
//

import Foundation
import CloudKit
import UIKit

struct SpotFromCloud: Hashable, Identifiable {
    let id: String
    let name: String
    let founder: String
    let description: String
    let date: String
    let location: CLLocation
    let type: String
    let imageURL: URL
    var image2URL: UIImage?
    var image3URL: UIImage?
    let isMultipleImages: Int
    var likes: Int
    var offensive: Int
    var spam: Int
    var inappropriate: Int
    var dangerous: Int
    let customLocation: Int
    let locationName: String
    let userID: String
    let dateObject: Date?
    let record: CKRecord
}

extension SpotFromCloud: SpotPreviewType {
    
    var parentIDPreview: String {
        id
    }
    
    var image2Preview: UIImage? {
        image2URL
    }
    
    var image3Preview: UIImage? {
        image3URL
    }
    
    var dataBaseIdPreview: String {
        record.recordID.recordName
    }
    
    var addedByPreview: String? {
        nil
    }
    
    var descriptionPreview: String {
        description
    }
    
    var locationPreview: CLLocation {
        location
    }
    
    var isMultipleImagesPreview: Bool {
        isMultipleImages != 0
    }
    
    var dateAddedToPlaylistPreview: Date? {
        nil
    }
    
    var userIDPreview: String {
        userID
    }
    
    var playlistPreview: Playlist? {
        nil
    }
    
    var isFromDiscover: Bool {
        true
    }
    
    var namePreview: String {
        name
    }
    
    var founderPreview: String {
        founder
    }
    
    var datePreview: String {
        date
    }
    
    var dateObjectPreview: Date? {
        dateObject
    }
    
    var imagePreview: UIImage? {
        let data = try? Data(contentsOf: imageURL)
        return UIImage(data: data ?? Data())
    }
    
    var locationNamePreview: String {
        locationName
    }
    
    var customLocationPreview: Bool {
        customLocation != 0
    }
    
    var tagsPreview: String {
        type
    }
    
    var isPublicPreview: Bool {
        true
    }
    
    var downloadsPreview: Int {
        likes
    }
}
