//
//  MapAnnotationDiscover.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI

struct SpotMapAnnotation<T: SpotPreviewType>: View {
    var spot: T
    var isSelected: Bool
    var color: Color

    var body: some View {
        VStack(spacing: 0) {
            annotationImage
            upsideDownTriangleImage
            if (isSelected) {
                spotName
            }
        }
    }
    
    private var spotName: some View {
        Text(spot.namePreview)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .foregroundColor(Color(UIColor.secondarySystemBackground))
            )
            .offset(y: -30)
    }
    
    private var upsideDownTriangleImage: some View {
        Image(systemName: "triangle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(color)
            .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
            .rotationEffect(Angle(degrees: 180))
            .offset(y: -1)
            .padding(.bottom , UIScreen.main.bounds.height * (40/812))
    }
    
    @ViewBuilder
    private var annotationImage: some View {
        if spot.playlistEmojiPreview != nil {
            emojiAnnotation
        } else {
            mapInCircle
        }
    }
    
    private var mapInCircle: some View {
        Image(systemName: "map.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.height * (30/812))
            .font(.headline)
            .foregroundColor(Color(UIColor.systemBackground))
            .padding(6)
            .background(color)
            .cornerRadius(36)
    }
    
    private var emojiAnnotation: some View {
        ZStack {
            Circle()
                .foregroundColor(Color(UIColor.systemBackground))
                .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                .offset(y: 8)
            Circle()
                .stroke(color, lineWidth: 2)
                .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                .padding(6)
                .offset(y: 8)
            Text(spot.playlistEmojiPreview ?? "🚫")
                .font(.system(size: 32))
                .offset(y: 8)
        }
    }
}
