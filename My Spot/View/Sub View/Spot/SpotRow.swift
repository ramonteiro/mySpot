//
//  SpotRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 SpotRow:
 view for each spot from db item in list in root view of my spots
 */

import SwiftUI
import CoreLocation

struct SpotRow<T: SpotPreviewType>: View {
    
    let spot: T
    let isShared: Bool
    @State private var scope:String = "Private".localized()
    @State private var tags: [String] = []
    @State private var exists = true
    @State private var distance: String = ""
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        HStack {
            ZStack {
                imageView
                if spot.isMultipleImagesPreview {
                    multipleImage
                }
            }
            content
            sharedCheckMarkForPlaylist
        }
        .onAppear {
            initializeValues()
        }
    }
    
    // MARK: - Sub Views
    
    private var multipleImage: some View {
        Image(systemName: "square.on.square")
            .foregroundColor(.white)
            .font(.subheadline)
            .offset(x: -35, y: -45)
    }
    
    private var imageView: some View {
        Image(uiImage: (spot.imagePreview ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 120)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.3), radius: 5)
    }
    
    private var name: some View {
        Text(spot.namePreview)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(2)
    }
    
    @ViewBuilder
    private var addedBy: some View {
        if let addedBy = spot.addedByPreview {
            Text("Added By: ".localized() + addedBy)
                .font(.subheadline)
                .foregroundColor(Color.gray)
                .lineLimit(1)
        }
    }
    
    @ViewBuilder
    private var downloadsOrScope: some View {
        if spot.isFromDiscover {
            HStack(alignment: .center) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                Text("\(spot.downloadsPreview)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        } else {
            HStack(alignment: .center) {
                Image(systemName: "globe")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                Text("\(scope)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        }
    }
    
    @ViewBuilder
    private var locationName: some View {
        if !spot.locationNamePreview.isEmpty {
            HStack(alignment: .center) {
                Image(systemName: (spot.customLocationPreview ? "mappin" : "figure.wave"))
                    .foregroundColor(Color.gray)
                    .font(.subheadline)
                Text(spot.locationNamePreview)
                    .foregroundColor(Color.gray)
                    .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    private var distanceAway: some View {
        if !distance.isEmpty {
            Text((distance) + " away".localized())
                .foregroundColor(Color.gray)
                .font(.subheadline)
        }
    }
    
    @ViewBuilder
    private var tagsView: some View {
        if !spot.tagsPreview.isEmpty {
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
            .padding(.bottom, 7)
            .padding(.top, -7)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading) {
            name
            addedBy
            downloadsOrScope
            locationName
            distanceAway
            tagsView
        }
        .padding(.leading, 5)
    }
    
    @ViewBuilder
    private var sharedCheckMarkForPlaylist: some View {
        if isShared {
            Spacer()
            checkMark
        }
    }
    
    private var checkMark: some View {
        VStack {
            Spacer()
            Image(systemName: "checkmark.square.fill")
                .foregroundColor(.green)
            Spacer()
        }
    }
    
    // MARK: - Functions
    
    private func initializeValues() {
        tags = spot.tagsPreview.components(separatedBy: ", ")
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
