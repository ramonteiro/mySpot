//
//  MapAnnotationDiscover.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI

struct MapAnnotationDiscover: View {
    var spot: SpotFromCloud
    @State private var colors:Color = .green
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .foregroundColor(Color(UIColor.systemBackground))
                    .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                    .offset(y: 8)
                Circle()
                    .stroke(.green, lineWidth: 2)
                    .frame(width: UIScreen.main.bounds.width * 9.5/100, height: UIScreen.main.bounds.height * (40/812), alignment: .center)
                    .padding(6)
                    .offset(y: 8)
                Text(spot.emoji)
                    .font(.system(size: 32))
                    .offset(y: 8)
            }
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.green)
                .frame(width: UIScreen.main.bounds.width * (10/375), height: UIScreen.main.bounds.height * (10/812))
                .rotationEffect(Angle(degrees: 180))
                .padding(.bottom , UIScreen.main.bounds.height * (40/812))
        }
    }
}
