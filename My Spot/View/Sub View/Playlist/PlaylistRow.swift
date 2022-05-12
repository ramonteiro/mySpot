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
    @ObservedObject var playlist: Playlist
    @State private var filteredSpots: [Spot] = []
    @State private var exists = true
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    let isShared: Bool
    let isSharing:Bool
    
    var body: some View {
        ZStack {
            if (exists) {
                HStack {
                    Text(playlist.emoji ?? "❓")
                        .font(.system(size: 50))
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("\(playlist.name ?? "")")
                                .font(.headline)
                                .fontWeight(.bold)
                                .lineLimit(2)
                            if (isShared) {
                                Image(systemName: "person.crop.circle")
                            }
                        }
                        
                        if (filteredSpots.count > 1) {
                            Text("\(filteredSpots.count) spots").font(.subheadline).foregroundColor(.gray)
                        } else if (filteredSpots.count == 1) {
                            Text("\(filteredSpots.count) spot").font(.subheadline).foregroundColor(.gray)
                        } else {
                            Text("Empty Playlist".localized()).font(.subheadline).foregroundColor(.gray)
                        }
                        
                        if !(filteredSpots.count == 0) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(filteredSpots, id: \.self) { spot in
                                        Text(spot.name ?? "")
                                            .font(.system(size: 12, weight: .regular))
                                            .lineLimit(2)
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(.tint)
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.leading, 5)
                }
                .onAppear {
                    if isSharing {
                        filteredSpots = playlist.spotArr.filter { spot in
                            spot.isShared
                        }
                    } else {
                        filteredSpots = playlist.spotArr
                    }
                }
            }
        }
        .onAppear {
            exists = checkIfItemExist()
        }
    }
    
    func checkIfItemExist() -> Bool {
        guard let _ = playlist.name else {return false}
        guard let _ = playlist.emoji else {return false}
        return true
    }
}

