//
//  DiscoverRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DiscoverRow:
 view for each spot from db item in list in root view
 */

import SwiftUI

struct DiscoverRow: View {
    var spot: SpotFromCloud

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(spot.name)
                Text("By: \(spot.founder)").font(.subheadline).foregroundColor(.gray)
                Text("On: \(spot.date)").font(.subheadline).foregroundColor(.gray)
                HStack(spacing: 0) {
                    Image(systemName: "hand.thumbsup.fill").font(.subheadline).foregroundColor(.gray)
                    Text("\(spot.likes)").font(.subheadline).foregroundColor(.gray)
                }
            }
            Spacer()
            Text(spot.emoji)
                .font(.system(size: 50))
                .overlay(Circle()
                            .stroke(Color.green, lineWidth: 1)
                            .frame(width: UIScreen.main.bounds.width * 0.16, height: UIScreen.main.bounds.height * (60/812), alignment: .center)
                )
        }
    }
}
