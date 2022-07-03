import SwiftUI

struct PlaylistView: View {
    
    @ObservedObject var viewModel: PlaylistViewModel
    var factory: PlaylistSubviewsFactory
    
    var body: some View {
        NavigationView {
            ZStack {
                factory.makeListPlaylists()
                    .navigationTitle("Playlists".localized())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            factory.makeAddPlaylistButton()
                        }
                    }
                if viewModel.persistence.playlists.count == 0 {
                    factory.makeNoPlaylistPrompt()
                }
            }
            .sheet(isPresented: $viewModel.presentAddPlaylistSheet) {
                AddPlaylistSheet(viewModel: viewModel)
            }
            .alert(isPresented: $viewModel.presentNoPermissionsAlert) {
                factory.makeAlertInvalidPermission()
            }
            .navigationViewStyle(.automatic)
        }
    }
    
}
