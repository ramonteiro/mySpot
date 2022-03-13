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
        HStack {
            displayImage
            displayName
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .cornerRadius(10)
    }
    
    private var displayImage: some View {
        ZStack {
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * (150/375), height: UIScreen.main.bounds.height * (150/812))
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
        .background(.red)
        .cornerRadius(10)
    }
    
    private var displayName: some View {
        VStack(spacing: 4) {
            Text(spot.name)
                .fontWeight(.bold)
            
            Text("By: \(spot.founder)")
                .font(.subheadline)
                .padding()
        }
        .frame(width: 125)
        .frame(alignment: .top)
    }
}
