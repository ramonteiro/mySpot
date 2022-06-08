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
    
    @FetchRequest(sortDescriptors: [
        SortDescriptor(\.name)
    ]) var playlists: FetchedResults<Playlist>
    @Environment(\.managedObjectContext) var moc
    private let stack = CoreDataStack.shared
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var showingDeleteAlert = false
    @State private var showingAddPlaylistSheet = false
    @State private var toBeDeleted: IndexSet?
    @State private var showNoPermissionsAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(playlists) { playlist in
                        NavigationLink(destination: DetailPlaylistView(playlist: playlist)) {
                            PlaylistRow(playlist: playlist, isShared: hasOnePart(playlist: playlist), isSharing: isSharing(playlist: playlist))
                                .alert(isPresented: self.$showingDeleteAlert) {
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
                        }
                    }
                    .onDelete(perform: deleteRow)
                }
                .onAppear {
                    UserDefaults.standard.set(0, forKey: "badgeplaylists")
                    cloudViewModel.resetBadgePlaylists()
                }
                .navigationTitle("Playlists".localized())
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button {
                            showingAddPlaylistSheet.toggle()
                        } label: {
                            Image(systemName: "plus").imageScale(.large)
                        }
                        .sheet(isPresented: $showingAddPlaylistSheet) {
                            AddPlaylistSheet()
                        }
                    }
                }
                if playlists.count == 0 {
                    noPlaylistPrompt
                }
            }
            .alert("Invalid Permission".localized(), isPresented: $showNoPermissionsAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Only the owner can delete. If you would like to leave the shared playlist, please tap the person icon and choose yourself.".localized())
            }
        }
        .navigationViewStyle(.automatic)
    }
    
    private func hasOnePart(playlist: Playlist) -> Bool {
        var isShared = false
        if stack.isShared(object: playlist) {
            let share = stack.getShare(playlist)
            share?.participants.forEach { participant in
                if (participant.acceptanceStatus == .accepted && participant.role != .owner) {
                    isShared = true
                }
            }
        }
        return isShared
    }
    
    private func isSharing(playlist: Playlist) -> Bool {
        return stack.isShared(object: playlist)
    }
    
    private var noPlaylistPrompt: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("No Playlists Here Yet!".localized())
                Spacer()
            }
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
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        self.toBeDeleted = indexSet
        self.showingDeleteAlert = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func delete(at offsets: IndexSet) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        offsets.forEach { i in
            if !stack.isShared(object: playlists[i]) {
                if (playlists[i].spotArr.count > 0) {
                    for place in playlists[i].spotArr {
                        place.playlist = nil
                    }
                }
                stack.delete(playlists[i])
            } else if stack.isOwner(object: playlists[i]) {
                stack.delete(playlists[i])
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                showNoPermissionsAlert = true
            }
            return
        }
    }
}
