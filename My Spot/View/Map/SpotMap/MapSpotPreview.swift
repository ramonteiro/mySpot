//
//  MapSpotPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI
import CoreLocation

struct MapSpotPreview<T: SpotPreviewType>: View {
    
    @Binding var spot: T
    @State private var tags: [String] = []
    @State private var padding: CGFloat = 20
    @State private var scope:String = "Private".localized()
    @State private var distance: String = ""
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        content
            .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
            .background { image }
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                .lineLimit(1)
        }
    }
    
    private var spotDownloads: some View {
        HStack {
            Image(systemName: "icloud.and.arrow.down")
                .font(.subheadline)
                .foregroundColor(.white)
            Text("\(spot.downloadsPreview)")
                .lineLimit(1)
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
                .lineLimit(1)
        }
    }
    
    private var spotName: some View {
        HStack {
            Text(spot.namePreview)
                .foregroundColor(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
                .lineLimit(2)
            Spacer()
        }
    }
    
    private var date: some View {
        Text(spot.dateObjectPreview?.toString() ?? ("By: \(spot.founderPreview)"))
            .font(.subheadline)
            .foregroundColor(.white)
            .lineLimit(1)
    }
    
    private var distanceAwayView: some View {
        Text("\(distance)")
            .foregroundColor(.white)
            .font(.subheadline)
            .onAppear {
                distance = mapViewModel.calculateDistance(from: spot.locationPreview)
            }
            .lineLimit(1)
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
                        .lineLimit(1)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(.tint, ignoresSafeAreaEdges: [])
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
        .padding(.horizontal, 5)
    }
    
    private var image: some View {
        Color.black.opacity(0.4)
            .background { imageRender.allowsHitTesting(false) }
    }
    
    @ViewBuilder
    private var imageRender: some View {
        if let image = spot.imagePreview {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.clear
                .if(spot.isFromDiscover) { view in
                    view.task {
                        spot.imagePreview = await cloudViewModel.fetchMainImage(id: spot.dataBaseIdPreview)
                    }
                }
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
