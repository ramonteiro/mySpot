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
    
    var body: some View {
        if (checkIfItemExist()) {
            HStack {
                Text(playlist.emoji ?? "❓")
                    .font(.system(size: 50))
                    .shadow(color: .black, radius: 5)
                
                VStack(alignment: .leading) {
                    Text("\(playlist.name ?? "")")
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                    
                    if (playlist.spotArr.count > 1) {
                        Text("\(playlist.spotArr.count) spots").font(.subheadline).foregroundColor(.gray)
                    } else if (playlist.spotArr.count == 1) {
                        Text("\(playlist.spotArr.count) spot").font(.subheadline).foregroundColor(.gray)
                    } else {
                        Text("Empty Playlist").font(.subheadline).foregroundColor(.gray)
                    }
                    
                    if !(playlist.spotArr.count == 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(playlist.spotArr, id: \.self) { spot in
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
        }
    }
    
    func checkIfItemExist() -> Bool {
        guard let _ = playlist.name else {return false}
        guard let _ = playlist.emoji else {return false}
        return true
    }
}

