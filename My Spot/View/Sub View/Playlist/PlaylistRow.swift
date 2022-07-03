//
//  PlaylistRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 PlaylistRow:
 view for each playlist item in list in root view
 */

import SwiftUI

struct PlaylistRow: View {
    let playlist: Playlist
    @State private var filteredSpots: [Spot] = []
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    let isShared: Bool
    let isSharing:Bool
    
    var body: some View {
        HStack {
            emoji
            content
        }
        .onAppear {
            filterSpots()
        }
    }
    
    // MARK: - Sub Views
    
    private var emoji: some View {
        Text(playlist.emoji ?? "❓")
            .font(.system(size: 50))
    }
    
    private var content: some View {
        VStack(alignment: .leading) {
            name
            numberOfSpots
            if filteredSpots.count > 0 {
                listOfSpots
            }
        }
        .padding(.leading, 5)
    }
    
    private var listOfSpots: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(filteredSpots, id: \.self) { spot in
                    Text(spot.name ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(.tint, ignoresSafeAreaEdges: [])
                        .cornerRadius(5)
                }
            }
        }
    }
    
    @ViewBuilder
    private var numberOfSpots: some View {
        if (filteredSpots.count > 1) {
            Text("\(filteredSpots.count) spots").font(.subheadline).foregroundColor(.gray)
        } else if (filteredSpots.count == 1) {
            Text("\(filteredSpots.count) spot").font(.subheadline).foregroundColor(.gray)
        } else {
            Text("Empty Playlist".localized()).font(.subheadline).foregroundColor(.gray)
        }
    }
    
    private var name: some View {
        HStack {
            Text("\(playlist.name ?? "")")
                .font(.headline)
                .fontWeight(.bold)
                .lineLimit(2)
            if (isShared) {
                Image(systemName: "person.crop.circle")
            }
        }
    }
    
    // MARK: - Functions
    
    private func filterSpots() {
        if isSharing {
            filteredSpots = playlist.spotArr.filter { spot in
                spot.isShared
            }
        } else {
            filteredSpots = playlist.spotArr
        }
    }
}

