//
//  TabController.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import Foundation

enum Tab {
    case spots
    case discover
    case playlists
}

class TabController: ObservableObject {
    @Published var activeTab = Tab.spots
    @Published var discoverPopToRoot = false
    @Published var spotPopToRoot = false
    @Published var playlistPopToRoot = false
    @Published var lastPressedTab = Tab.spots
    
    func open(_ tab: Tab) {
        activeTab = tab
    }
}
