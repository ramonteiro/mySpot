//
//  WidgetTile.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import SwiftUI

struct WidgetTile: View {
    
    let spot: Spot
    let distance: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Link(destination: URL(string: "myspot://" + (spot.spotid))!) {
                    Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
                Color.black.opacity(0.3)
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    titleName
                    if (!(spot.locationName.isEmpty)) {
                        locationName
                    }
                    distanceAway
                }
                .frame(width: geo.size.width)
            }
            .cornerRadius(20)
        }
    }
    
    private var titleName: some View {
        HStack {
            Text(spot.name)
                .foregroundColor(.white)
                .font(.system(size: 18))
                .fontWeight(.bold)
                .lineLimit(1)
            Spacer()
        }
        .padding(.leading, 10)
    }
    
    private var locationName: some View {
        HStack(spacing: 5) {
            Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(spot.locationName)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(1)
            Spacer()
        }
        .padding(.leading, 10)
    }
    
    private var distanceAway: some View {
        HStack {
            Text(distance)
                .foregroundColor(.white)
                .font(.system(size: 14))
                .lineLimit(1)
            Spacer()
        }
        .padding([.leading, .bottom], 10)
    }
}
