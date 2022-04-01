//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @StateObject private var tabController = TabController()
    @State private var showSharedSpotSheet = false
    @State private var errorAlert = false
    
    var body: some View {
        TabView(selection: $tabController.activeTab) {
            MySpotsView()
                .tabItem() {
                    Image(systemName: "mappin.and.ellipse")
                    Text("My Spots")
                }
                .tag(Tab.spots)
            DiscoverView()
                .tabItem() {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(Tab.discover)
            PlaylistView()
                .tabItem() {
                    Image(systemName: "books.vertical")
                    Text("Playlists")
                }
                .tag(Tab.playlists)
        }
        .onChange(of: scenePhase, perform: { newValue in
            if newValue == .active {
                cloudViewModel.getiCloudStatus()
                mapViewModel.checkLocationAuthorization()
                cloudViewModel.checkIfNotiEnabled()
            }
        })
        .onReceive(tabController.$activeTab) { selection in
            if (selection == Tab.spots) {
                // spot pressed
                
                if (selection == tabController.lastPressedTab) {
                    // spot pressed while in spot
                    tabController.spotPopToRoot.toggle()
                }
            }
            if (selection == Tab.playlists) {
                // playlist pressed
                
                if (selection == tabController.lastPressedTab) {
                    // playlist pressed while in playlist
                    tabController.playlistPopToRoot.toggle()
                }
            }
            if (selection == Tab.discover) {
                // discover pressed
                
                if (selection == tabController.lastPressedTab) {
                    // discover pressed while in discover
                    tabController.discoverPopToRoot.toggle()
                }
            }
            
            // set last changed tab
            tabController.lastPressedTab = selection
        }
        .fullScreenCover(isPresented: $showSharedSpotSheet, onDismiss: {
            cloudViewModel.shared = []
        }, content: {
            DiscoverSheetShared()
        })
        .onChange(of: cloudViewModel.shared.count) { newValue in
            if newValue == 1 {
                showSharedSpotSheet = true
            }
        }
        .onChange(of: cloudViewModel.isError) { newValue in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            errorAlert.toggle()
        }
        .alert(cloudViewModel.isErrorMessage, isPresented: $errorAlert) {
            Button("Dismiss", role: .cancel) { }
        }
        .environmentObject(tabController)
    }
}
