//
//  DiscoverMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI
import MapKit

struct DiscoverMapPreview: View {
    
    var spot: SpotFromCloud
    @State private var imageLoaded: Bool = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                displayImage
                displayName
            }
            
            VStack(spacing: 0) {
                Text(spot.description)
                    .frame(height: UIScreen.main.bounds.height * (120/812))
                    .truncationMode(.tail)
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
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * (100/375), height: UIScreen.main.bounds.height * (100/812))
                    .cornerRadius(10)
                    .onAppear {
                        imageLoaded = true
                    }
            } else {
                HStack {
                    Spacer()
                    ProgressView("Loading Image")
                    Spacer()
                }
                .onAppear {
                    imageLoaded = false
                }
            }
        }
        .padding(6)
        .background(Color.green)
        .cornerRadius(10)
    }
    
    private var displayName: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .fontWeight(.bold)
            
            Text("By: \(spot.founder)")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
