//
//  PlaylistSubviewsFactory.swift
//  My Spot
//
//  Created by Raphael Monteiro on 29/06/22.
//

import SwiftUI

struct PlaylistSubviewsFactory {
    
    @ObservedObject var viewModel: PlaylistViewModel
    
    func makeListPlaylists() -> some View {
        List {
            ForEach(viewModel.persistence.playlists) { playlist in
                NavigationLink(destination: DetailPlaylistView(playlist: playlist)) {
                    PlaylistRow(playlist: playlist,
                                isShared: viewModel.hasOnePart(playlist: playlist),
                                isSharing: viewModel.isSharing(playlist: playlist))
                    .alert(isPresented: $viewModel.presentDeleteAlert) {
                        viewModel.removePlaylistAlert
                    }
                }
            }
            .onDelete(perform: viewModel.deleteRow)
            .onAppear(perform: resetBadges)
        }
    }
    
    func makeAddPlaylistButton() -> some View {
        Button {
            viewModel.presentAddPlaylistSheet.toggle()
        } label: {
            Image(systemName: "plus").imageScale(.large)
        }
    }
    
    func makeNoPlaylistPrompt() -> some View {
        VStack(spacing: 6) {
            makeNoPlaylistPromptTitle()
            makeNoPlaylistPromptSubtitle()
        }
    }
    
    private func makeNoPlaylistPromptTitle() -> some View {
        HStack {
            Spacer()
            Text("No Playlists Here Yet!".localized())
            Spacer()
        }
    }
    
    private func makeNoPlaylistPromptSubtitle() -> some View {
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
    
    private func resetBadges() {
        UserDefaults.standard.set(0, forKey: "badgeplaylists")
        viewModel.cloudViewModel.resetBadgePlaylists()
    }
    
    func makeAlertInvalidPermission() -> Alert {
        Alert(
            title: Text("Invalid Permission".localized()),
            message: Text("Only the owner can delete. If you would like to leave the shared playlist, please tap the person icon and choose yourself.".localized()),
            dismissButton: .cancel()
        )
    }
    
}

