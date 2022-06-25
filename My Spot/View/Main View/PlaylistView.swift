//
//  PlaylistView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 PlaylistView:
 root of tabbar for playlist, shows all playlist
 */

import SwiftUI

struct PlaylistView: View {
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) var playlists: FetchedResults<Playlist>
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var presentDeleteAlert = false
    @State private var presentAddPlaylistSheet = false
    @State private var presentNoPermissionsAlert = false
    @State private var toBeDeleted: IndexSet?
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    listPlaylists
                }
                .onAppear {
                    resetBadges()
                }
                .navigationTitle("Playlists".localized())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        addPlaylistButton
                    }
                }
                if playlists.count == 0 {
                    noPlaylistPrompt
                }
            }
            .sheet(isPresented: $presentAddPlaylistSheet) {
                AddPlaylistSheet()
            }
            .alert("Invalid Permission".localized(), isPresented: $presentNoPermissionsAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Only the owner can delete. If you would like to leave the shared playlist, please tap the person icon and choose yourself.".localized())
            }
        }
        .navigationViewStyle(.automatic)
    }
    
    // MARK: - Sub Views
    
    private var listPlaylists: some View {
        ForEach(playlists) { playlist in
            NavigationLink(destination: DetailPlaylistView(playlist: playlist)) {
                PlaylistRow(playlist: playlist,
                            isShared: hasOnePart(playlist: playlist),
                            isSharing: isSharing(playlist: playlist))
                    .alert(isPresented: self.$presentDeleteAlert) {
                        removePlaylistAlert
                    }
            }
        }
        .onDelete(perform: deleteRow)
    }
    
    private var addPlaylistButton: some View {
        Button {
            presentAddPlaylistSheet.toggle()
        } label: {
            Image(systemName: "plus").imageScale(.large)
        }
    }
    
    private var noPlaylistPrompt: some View {
        VStack(spacing: 6) {
            noPlaylistPromptTitle
            noPlaylistPromptSubtitle
        }
    }
    
    private var noPlaylistPromptTitle: some View {
        HStack {
            Spacer()
            Text("No Playlists Here Yet!".localized())
            Spacer()
        }
    }
    
    private var noPlaylistPromptSubtitle: some View {
        HStack {
            Spacer()
            HStack {
                Text("Add Some With The".localized())
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Image(systemName: "plus")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Button Above".localized())
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var removePlaylistAlert: Alert {
        Alert(title: Text("Are you sure you want to delete?".localized()),
              message: Text("If you are the owner of a shared playlist, all participants will no longer have access.".localized()),
              primaryButton: .destructive(Text("Delete".localized())) {
            self.delete(at: self.toBeDeleted!)
            self.toBeDeleted = nil
        }, secondaryButton: .cancel() {
            self.toBeDeleted = nil
        }
        )
    }
    
    // MARK: - Functions
    
    private func resetBadges() {
        UserDefaults.standard.set(0, forKey: "badgeplaylists")
        cloudViewModel.resetBadgePlaylists()
    }
    
    private func hasOnePart(playlist: Playlist) -> Bool {
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
    
    private func isSharing(playlist: Playlist) -> Bool {
        return CoreDataStack.shared.isShared(object: playlist)
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        self.toBeDeleted = indexSet
        self.presentDeleteAlert = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func delete(at offsets: IndexSet) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        offsets.forEach { i in
            if !CoreDataStack.shared.isShared(object: playlists[i]) {
                if (playlists[i].spotArr.count > 0) {
                    for place in playlists[i].spotArr {
                        place.playlist = nil
                    }
                }
                CoreDataStack.shared.delete(playlists[i])
            } else if CoreDataStack.shared.isOwner(object: playlists[i]) {
                CoreDataStack.shared.delete(playlists[i])
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                presentNoPermissionsAlert = true
            }
            return
        }
    }
}
