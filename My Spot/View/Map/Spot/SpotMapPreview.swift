//
//  SpotMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/1/22.
//

import SwiftUI
import CoreLocation

struct SpotMapPreview: View {
    
    let spot: Spot
    @State private var padding: CGFloat = 20
    @State private var scope:String = "Private".localized()
    @State private var tags: [String] = []
    @State private var distance: String = ""
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                displayImage
                content
            }
        }
        .onAppear {
            initializeValues()
        }
    }
    
    // MARK: - Sub Views
    
    private var content: some View {
        VStack {
            topRow
            Spacer()
            spotName
            bottomRow
            if (!(spot.tags?.isEmpty ?? true)) {
                tagsView
            }
        }
        .padding(.horizontal)
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
    
    private var bottomRow: some View {
        HStack {
            founder
            Spacer()
            distanceAway
        }
        .padding(.bottom, padding)
    }
    
    @ViewBuilder
    private var distanceAway: some View {
        if (!distance.isEmpty) {
            Text((distance) + " away".localized())
                .foregroundColor(.white)
                .font(.subheadline)
        } else {
            Text(spot.date?.components(separatedBy: ";")[0] ?? "")
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    private var founder: some View {
        if spot.addedBy == nil {
            Text("By: ".localized() + (spot.founder ?? ""))
                .font(.subheadline)
                .foregroundColor(.white)
        } else {
            Text("Added By: ".localized() + (spot.addedBy ?? ""))
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var spotName: some View {
        HStack {
            Text(spot.name ?? "")
                .foregroundColor(.white)
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
        }
    }
    
    private var topRow: some View {
        HStack {
            locationName
            Spacer()
            spotScope
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
    
    @ViewBuilder
    private var locationName: some View {
        if (!(spot.locationName?.isEmpty ?? true)) {
            Image(systemName: (!spot.wasThere ? "mappin" : "figure.wave"))
                .font(.subheadline)
                .foregroundColor(.white)
            Text(spot.locationName ?? "")
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
    
    private var displayImage: some View {
        ZStack {
            Image(uiImage: (spot.image ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            Color.black.opacity(0.4)
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .cornerRadius(40)
        }
    }
    
    // MARK: - Functions
    
    private func initializeValues() {
        tags = spot.tags?.components(separatedBy: ", ") ?? []
        if (spot.isPublic) {
            scope = "Public".localized()
        } else {
            scope = "Private".localized()
        }
        if (mapViewModel.isAuthorized) {
            distance = mapViewModel.calculateDistance(from: CLLocation(latitude: spot.x, longitude: spot.y))
        }
    }
}
