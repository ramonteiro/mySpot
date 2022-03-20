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
    @ObservedObject var spot: Spot
    var isSelected: Bool

    var body: some View {
        ZStack {
            if (spot.playlist == nil) {
                VStack(spacing: 0) {
                    Image(systemName: "map.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.08, height: UIScreen.main.bounds.height * (30/812))
                        .font(.headline)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .padding(6)
                        .background(.red)
                        .cornerRadius(36)
                    
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
                        .rotationEffect(Angle(degrees: 180))
                        .offset(y: -1)
                        .padding(.bottom , UIScreen.main.bounds.height * (40/812))
                    if (isSelected) {
                        Text(spot.name ?? "")
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundColor(Color(UIColor.secondarySystemBackground))
                            )
                            .offset(y: -30)
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                            .offset(y: 8)
                        Circle()
                            .stroke(.red, lineWidth: 2)
                            .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                            .padding(6)
                            .offset(y: 8)
                        Text(spot.playlist?.emoji ?? "🚫")
                            .font(.system(size: 32))
                            .offset(y: 8)
                    }
                    
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.red)
                        .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
                        .rotationEffect(Angle(degrees: 180))
                        .padding(.bottom , UIScreen.main.bounds.height * (40/812))
                    if (isSelected) {
                        Text(spot.name ?? "")
                            .padding(5)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .foregroundColor(Color(UIColor.secondarySystemBackground))
                            )
                            .offset(y: -30)
                    }
                }
            }
        }
    }
}
