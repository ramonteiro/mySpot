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
                VStack(alignment: .leading) {
                    Text(playlist.name!)
                    if (playlist.spotArr.count > 1) {
                        Text("\(playlist.spotArr.count) spots").font(.subheadline).foregroundColor(.gray)
                    } else if (playlist.spotArr.count == 1) {
                        Text("\(playlist.spotArr.count) spot").font(.subheadline).foregroundColor(.gray)
                    } else {
                        Text("Empty Playlist").font(.subheadline).foregroundColor(.gray)
                    }
                }
                Spacer()
                Text(playlist.emoji!)
                    .font(.system(size: 50))
                    .overlay(Circle()
                                .stroke(Color.red, lineWidth: 1)
                                .frame(width: UIScreen.main.bounds.width * 0.16, height: UIScreen.main.bounds.height * (60/812), alignment: .center)
                    )
                    .padding()
            }
        }
        
    }
    
    func checkIfItemExist() -> Bool {
        if let _ = playlist.name {
            return true
        } else {
            return false
        }
    }
}
