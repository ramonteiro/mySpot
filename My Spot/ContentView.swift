//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var mapViewModel: MapViewModel
    @StateObject var cloudViewModel: CloudKitViewModel
    
    @StateObject private var tabController = TabController()
    
    var body: some View {
        TabView(selection: $tabController.activeTab) {
            MySpotsView(mapViewModel: mapViewModel, cloudViewModel: cloudViewModel)
                .tabItem() {
                    Image(systemName: "mappin.and.ellipse")
                    Text("My Spots")
                }
                .tag(Tab.spots)
                .accentColor(.red)
            DiscoverView(mapViewModel: mapViewModel, cloudViewModel: cloudViewModel)
                .tabItem() {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(Tab.discover)
                .accentColor(.red)
            PlaylistView(mapViewModel: mapViewModel, cloudViewModel: cloudViewModel)
                .tabItem() {
                    Image(systemName: "books.vertical")
                    Text("Playlists")
                }
                .tag(Tab.playlists)
                .accentColor(.red)
        }
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
        .accentColor(.red)
        .environmentObject(tabController)
    }
}
