//
//  PlaylistPersistence.swift
//  My Spot
//
//  Created by Raphael Monteiro on 28/06/22.
//

import Foundation
import CoreData
import os.log

/// Manages Playlist entity local and cloud persistence.
final class PlaylistPersistenceManager: ObservableObject {
    
    @Published var playlists = [Playlist]()
    let context = CoreDataStack.shared.context
    let logger = Logger(subsystem: "mySpot", category: "PlaylistPersistenceManager")
    
    init() {
        loadPlaylists()
    }
    
    func loadPlaylists() {
            let fetchRequest: NSFetchRequest<Playlist> = Playlist.fetchRequest()
            do {
                playlists = try context.fetch(fetchRequest)
            } catch {
                logger.error("\(error.localizedDescription)")
            }
    }
    
    func savePlaylist(name: String, emoji: String) {
            let newPlaylist = Playlist(context: context)
            newPlaylist.id = UUID()
            newPlaylist.name = name
            newPlaylist.emoji = emoji
            saveContext()
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                loadPlaylists()
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
    
    func delete(_ playlist: Playlist) {
        context.perform {
            self.context.delete(playlist)
            self.saveContext()
        }
    }
    
}

