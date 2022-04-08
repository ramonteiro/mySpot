//
//  MapAnnotationDiscover.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI

struct MapAnnotationDiscover: View {
    var spot: SpotFromCloud
    var isSelected: Bool
    var color: Color
    @EnvironmentObject var cloudViewModel: CloudKitViewModel

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "map.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.height * (30/812))
                .font(.headline)
                .foregroundColor(Color(UIColor.systemBackground))
                .padding(6)
                .background(color)
                .cornerRadius(36)
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -1)
                .padding(.bottom , UIScreen.main.bounds.height * (40/812))
            if (isSelected) {
                Text(spot.name)
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .foregroundColor(Color(UIColor.secondarySystemBackground))
                    )
                    .offset(y: -30)
                    .lineLimit(1)
            }
        }
    }
}
