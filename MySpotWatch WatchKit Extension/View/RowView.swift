//
//  RowView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct RowView: View {
    let spot: Spot
    
    var body: some View {
        HStack(spacing: 5) {
            Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .cornerRadius(10)
            VStack {
                Text(spot.name)
                    .font(.system(size: 16))
                    .lineLimit(2)
                if !spot.locationName.isEmpty {
                    HStack {
                        Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                            .font(.system(size: 12))
                        Text(spot.locationName)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}
