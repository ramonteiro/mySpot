//
//  DiscoverMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI
import CoreLocation

struct DiscoverMapPreview: View {
    
    let spot: SpotFromCloud
    @State private var tags: [String] = []
    @State private var padding: CGFloat = 20
    @State private var distance: String = ""
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                image
                content
            }
        }
    }
    
    private var locationName: some View {
        HStack {
            Image(systemName: (spot.customLocation != 0 ? "mappin" : "figure.wave"))
                .font(.subheadline)
                .foregroundColor(.white)
            Text(spot.locationName)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var spotDownloads: some View {
        HStack {
            Image(systemName: "icloud.and.arrow.down")
                .font(.subheadline)
                .foregroundColor(.white)
            Text("\(spot.likes)")
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var topRow: some View {
        HStack {
            if (!spot.locationName.isEmpty) {
                locationName
            }
            Spacer()
            spotDownloads
        }
        .padding(.top)
    }
    
    private var spotName: some View {
        HStack {
            if (!spot.locationName.isEmpty) {
                locationName
            }
            Spacer()
            spotDownloads
        }
        .padding(.top)
    }
    
    private var date: some View {
        Text(spot.dateObject?.toString() ?? ("By: \(spot.founder)"))
            .font(.subheadline)
            .foregroundColor(.white)
    }
    
    private var distanceAwayView: some View {
        Text("\(distance)")
            .foregroundColor(.white)
            .font(.subheadline)
            .onAppear {
                distance = mapViewModel.calculateDistance(from: spot.location)
            }
    }
    
    private var bottomRow: some View {
        HStack {
            date
            Spacer()
            distanceAwayView
        }
        .padding(.bottom, padding)
    }
    
    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(spot.type.components(separatedBy: ", "), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(.tint)
                        .cornerRadius(5)
                }
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            padding = 2
        }
    }
    
    private var content: some View {
        VStack {
            topRow
            Spacer()
            spotName
            bottomRow
            if (!(spot.type.isEmpty)) {
                tagsView
            }
        }
        .padding(.horizontal)
    }
    
    private var image: some View {
        ZStack {
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            Color.black.opacity(0.4)
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .cornerRadius(40)
        }
    }
}
