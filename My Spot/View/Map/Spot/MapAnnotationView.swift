//
//  MapAnnotationView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/23/22.
//

/*
 MapAnnotation:
 custom image displayed over map pins
 */

import SwiftUI

struct MapAnnotationView: View {
    
    let spot: Spot
    var isSelected: Bool
    var color: Color

    var body: some View {
        ZStack {
            if (spot.playlist == nil) {
                spotAnnotationWithNoPlaylist
            } else {
                spotAnnotationWithPlaylist
            }
        }
    }
    
    private var spotAnnotationWithNoPlaylist: some View {
        VStack(spacing: 0) {
            mapImage
            upsidedownTriangle
            if (isSelected) {
                spotName
            }
        }
    }
    
    private var spotName: some View {
        Text(spot.name ?? "")
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .foregroundColor(Color(UIColor.secondarySystemBackground))
            )
            .offset(y: -30)
    }
    
    private var mapImage: some View {
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
    
    private var upsidedownTriangle: some View {
        Image(systemName: "triangle.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(color)
            .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
            .rotationEffect(Angle(degrees: 180))
            .offset(y: -1)
            .padding(.bottom , UIScreen.main.bounds.height * (40/812))
    }
    
    private var spotAnnotationWithPlaylist: some View {
        VStack(spacing: 0) {
            emojiAnnotation
            upsidedownTriangle
            if (isSelected) {
                spotName
            }
        }
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
            Text(spot.playlist?.emoji ?? "🚫")
                .font(.system(size: 32))
                .offset(y: 8)
        }
    }
}
