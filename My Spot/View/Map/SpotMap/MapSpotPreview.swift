//
//  MapSpotPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI
import CoreLocation

struct MapSpotPreview<T: SpotPreviewType>: View {
    
    let spot: T
    @State private var tags: [String] = []
    @State private var padding: CGFloat = 20
    @State private var scope:String = "Private".localized()
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
        .onAppear {
            initializeValues()
        }
    }
    
    // MARK: - Sub Views
    
    private var locationName: some View {
        HStack {
            Image(systemName: (spot.customLocationPreview ? "mappin" : "figure.wave"))
                .font(.subheadline)
                .foregroundColor(.white)
            Text(spot.locationNamePreview)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var spotDownloads: some View {
        HStack {
            Image(systemName: "icloud.and.arrow.down")
                .font(.subheadline)
                .foregroundColor(.white)
            Text("\(spot.downloadsPreview)")
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var topRow: some View {
        HStack {
            if !spot.locationNamePreview.isEmpty {
                locationName
            }
            Spacer()
            if spot.isFromDiscover {
                spotDownloads
            } else {
                spotScope
            }
        }
        .padding(.top)
    }
    
    private var spotScope: some View {
        HStack {
            Image(systemName: "globe")
                .font(.subheadline)
                .foregroundColor(.white)
            Text(scope)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var spotName: some View {
        HStack {
            Text(spot.namePreview)
                .foregroundColor(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    private var date: some View {
        Text(spot.dateObjectPreview?.toString() ?? ("By: \(spot.founderPreview)"))
            .font(.subheadline)
            .foregroundColor(.white)
    }
    
    private var distanceAwayView: some View {
        Text("\(distance)")
            .foregroundColor(.white)
            .font(.subheadline)
            .onAppear {
                distance = mapViewModel.calculateDistance(from: spot.locationPreview)
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
                ForEach(tags, id: \.self) { tag in
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
            if !spot.tagsPreview.isEmpty {
                tagsView
            }
        }
        .padding(.horizontal)
    }
    
    private var image: some View {
        ZStack {
            if let image = spot.imagePreview {
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
    
    // MARK: - Functions
    
    private func initializeValues() {
        if !spot.tagsPreview.isEmpty {
            tags = spot.tagsPreview.components(separatedBy: ", ")
        }
        if (spot.isPublicPreview) {
            scope = "Public".localized()
        } else {
            scope = "Private".localized()
        }
        if (mapViewModel.isAuthorized) {
            distance = mapViewModel.calculateDistance(from: spot.locationPreview)
        }
    }
}
