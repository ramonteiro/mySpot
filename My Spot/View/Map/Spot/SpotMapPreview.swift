//
//  SpotMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/1/22.
//

import SwiftUI
import MapKit

struct SpotMapPreview: View {
    
    let spot: Spot
    @State private var colors:Color = Color.red
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                displayImage
                displayName
            }
            
            VStack(spacing: 0) {
                Text(spot.details!)
                    .frame(height: UIScreen.main.bounds.height * (120/812))
                    .truncationMode(.tail)
            }
        }
        .onAppear {
            if spot.isPublic {
                colors = Color.green
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .offset(y: 65)
        )
        .cornerRadius(10)
    }
    
    private var displayImage: some View {
        ZStack {
            if let image = spot.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * (100/375), height: UIScreen.main.bounds.height * (100/812))
                    .cornerRadius(10)
            }
        }
        .padding(6)
        .background(colors)
        .cornerRadius(10)
    }
    
    private var displayName: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name!)
                .fontWeight(.bold)
            
            Text("By: \(spot.founder!)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
