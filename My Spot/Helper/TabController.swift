//
//  TabController.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

/*
 Controls the switch between tabs to allow for tabbar functions
 such as tab again to return to root or tap after in root to scroll to top
 */

import Foundation

enum Tab {
    case spots
    case discover
    case playlists
    case profile
}

class TabController: ObservableObject {
    @Published var activeTab = Tab.spots
    @Published var discoverPopToRoot = false
    @Published var spotPopToRoot = false
    @Published var playlistPopToRoot = false
    @Published var profilePopToRoot = false
    @Published var lastPressedTab = Tab.spots
    
    func open(_ tab: Tab) {
        activeTab = tab
    }
}
