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
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var showingAddPlaylistSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(playlists) { playlist in
                        NavigationLink(destination: DetailPlaylistView(playlist: playlist)) {
                            PlaylistRow(playlist: playlist)
                        }
                    }
                    .onDelete(perform: self.delete)
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
        }
        .navigationViewStyle(.automatic)
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
    
    private func delete(at offsets: IndexSet) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        offsets.forEach { i in
            if (playlists[i].spotArr.count > 0) {
                for place in playlists[i].spotArr {
                    place.playlist = nil
                }
            }
            moc.delete(playlists[i])
            try? moc.save()
            return
        }
    }
}
