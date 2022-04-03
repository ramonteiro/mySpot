//
//  DiscoverRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DiscoverRow:
 view for each spot from db item in list in root view
 */

import SwiftUI
import CoreLocation

struct DiscoverRow: View {
    var spot: SpotFromCloud
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            ZStack {
                if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                } else {
                    ProgressView("Loading Image")
                        .frame(width: 100, height: 120, alignment: .center)
                        .cornerRadius(20)
                }
                if (spot.isMultipleImages != 0) {
                    Image(systemName: "square.on.square")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .offset(x: -35, y: -45)
                }
            }
            
            VStack(alignment: .leading) {
                Text("\(spot.name)")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text("By: \(spot.founder)")
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                
                HStack(alignment: .center) {
                    Image(systemName: "heart.fill")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Text("\(spot.likes)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                if (!spot.locationName.isEmpty) {
                    HStack(alignment: .center) {
                        Image(systemName: "mappin")
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                        Text(spot.locationName)
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                    }
                }
                Text("\(calculateDistance())")
                    .foregroundColor(Color.gray)
                    .font(.subheadline)
                
                if (!(spot.type.isEmpty)) {
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
                    .padding(.bottom, 7)
                    .padding(.top, -7)
                }
            }
            .padding(.leading, 5)
        }
    }
    
    private func calculateDistance() -> String {
        if !mapViewModel.isAuthorized {
            return "Cannot Find Location"
        }
        var distance = ""
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let distanceInMeters = userLocation.distance(from: spot.location)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            distance = String(format: "%.1f", distanceDouble) + " km away"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            distance = String(format: "%.1f", distanceDouble) + " mi away"
        }
        return distance
        
    }
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}
