//
//  CloudSharingController.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/9/22.
//

import CloudKit
import SwiftUI

struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let playlist: Playlist
    
    func makeCoordinator() -> CloudSharingCoordinator {
        CloudSharingCoordinator(playlist: playlist)
    }
    
    func makeUIViewController(context: Context) -> UICloudSharingController {
        share[CKShare.SystemFieldKey.title] = playlist.name
        share[CKShare.SystemFieldKey.thumbnailImageData] = playlist.emoji?.image()
        let controller = UICloudSharingController(share: share, container: container)
        controller.modalPresentationStyle = .formSheet
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowReadOnly]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {
    }
}

final class CloudSharingCoordinator: NSObject, UICloudSharingControllerDelegate {
    let stack = CoreDataStack.shared
    let playlist: Playlist
    init(playlist: Playlist) {
        self.playlist = playlist
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        playlist.name
    }
    
    func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        playlist.emoji?.image()
    }
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        // TODO: Failed to save message
        print("Failed to save share: \(error)")
    }
    
    func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("Saved the share")
    }
    
    func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        if !stack.isOwner(object: playlist) {
            stack.delete(playlist)
        }
    }
}
