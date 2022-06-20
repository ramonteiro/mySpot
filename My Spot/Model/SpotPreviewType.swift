//
//  SpotPreviewType.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/19/22.
//

import Foundation
import UIKit
import CoreLocation

protocol SpotPreviewType: Identifiable, Hashable {
    var namePreview: String { get }
    var founderPreview: String { get }
    var datePreview: String { get }
    var dateObjectPreview: Date? { get }
    var imagePreview: UIImage? { get }
    var locationNamePreview: String { get }
    var customLocationPreview: Bool { get }
    var tagsPreview: String { get }
    var isPublicPreview: Bool { get }
    var downloadsPreview: Int { get }
    var isFromDiscover: Bool { get }
    var playlistPreview: Playlist? { get }
    var descriptionPreview: String { get }
    var locationPreview: CLLocation { get }
    var isMultipleImagesPreview: Bool { get }
    var dateAddedToPlaylistPreview: Date? { get }
    var userIDPreview: String { get }
    var addedByPreview: String? { get }
}
