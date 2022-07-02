//
//  PlaylistViewModel.swift
//  My Spot
//
//  Created by Raphael Monteiro on 28/06/22.
//

import SwiftUI

final class PlaylistViewModel: ObservableObject {
    
    @ObservedObject var persistence = PlaylistPersistenceManager()
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var cloudViewModel: CloudKitViewModel
    
    @Published var presentDeleteAlert = false
    @Published var presentAddPlaylistSheet = false
    @Published var presentNoPermissionsAlert = false
    var playlistToDelete: Playlist?
    
    init(mapViewModel: MapViewModel, cloudViewModel: CloudKitViewModel) {
        self.mapViewModel = mapViewModel
        self.cloudViewModel = cloudViewModel
        persistence.loadPlaylists()
    }
    
    func hasOnePart(playlist: Playlist) -> Bool {
        var isShared = false
        if CoreDataStack.shared.isShared(object: playlist) {
            let share = CoreDataStack.shared.getShare(playlist)
            share?.participants.forEach { participant in
                if (participant.acceptanceStatus == .accepted && participant.role != .owner) {
                    isShared = true
                }
            }
        }
        return isShared
    }
    
    func isSharing(playlist: Playlist) -> Bool {
        return CoreDataStack.shared.isShared(object: playlist)
    }
    
    func deleteRow(at indexSet: IndexSet) {
        self.presentDeleteAlert = true
        playlistToDelete = persistence.playlists[indexSet.first!]
    }
    
    var removePlaylistAlert: Alert {
        Alert(title: Text("Are you sure you want to delete?".localized()),
              message: Text("If you are the owner of a shared playlist, all participants will no longer have access.".localized()),
              primaryButton: .destructive(Text("Delete".localized())) {
            self.persistence.delete(self.playlistToDelete!)
        }, secondaryButton: .cancel() {
            self.presentDeleteAlert = false
        }
        )
    }
    
}
