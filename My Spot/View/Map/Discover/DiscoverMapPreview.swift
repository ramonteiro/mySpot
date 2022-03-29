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
    @State private var pad:CGFloat = 20
    @State private var distance: String = ""
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                displayImage
                VStack {
                    HStack {
                        if (!spot.locationName.isEmpty) {
                            Image(systemName: "mappin")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(spot.locationName)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(spot.likes)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    Spacer()
                    HStack {
                        Text(spot.name)
                            .foregroundColor(.white)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Text("By: \(spot.founder)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        if (!distance.isEmpty) {
                            Text("\(distance) away")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                        } else {
                            Text(spot.date.components(separatedBy: ";")[0])
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, pad)
                    if (!(spot.type.isEmpty)) {
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
                            pad = 2
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            tags = spot.type.components(separatedBy: ", ")
            if (mapViewModel.isAuthorized) {
                calculateDistance()
            }
        }
    }
    
    private var displayImage: some View {
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
            Color.black.opacity(0.5)
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .cornerRadius(40)
        }
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let distanceInMeters = userLocation.distance(from: spot.location)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            distance = String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            distance = String(format: "%.1f", distanceDouble) + " mi"
        }
        
    }
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}
