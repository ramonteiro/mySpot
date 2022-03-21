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

struct SpotRow: View {
    @ObservedObject var spot: Spot
    @State private var scope:String = "Private"
    @State private var tags: [String] = []
    @State private var exists = true
    @State private var distance: String = ""
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        ZStack {
            if (exists) {
                displayRedCircleImage
            }
        }
        .onAppear {
            exists = checkIfItemExist()
        }
    }
    
    private func checkIfItemExist() -> Bool {
        if let _ = spot.name {
            return true
        } else {
            return false
        }
    }
    
    private var displayRedCircleImage: some View {
        HStack {
            Image(uiImage: (spot.image ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 120)
                .cornerRadius(20)
                .shadow(color: .black, radius: 5)
            
            VStack(alignment: .leading) {
                Text("\(spot.name ?? "")")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text("By: \(spot.founder ?? "")")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
                
                HStack(alignment: .center) {
                    Image(systemName: "globe")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Text("\(scope)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                if (!(spot.locationName?.isEmpty ?? true)) {
                    HStack(alignment: .center) {
                        Image(systemName: "mappin")
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                        Text(spot.locationName ?? "")
                            .foregroundColor(Color.gray)
                            .font(.subheadline)
                    }
                }
                if (!distance.isEmpty) {
                    Text("\(distance) away")
                        .foregroundColor(Color.gray)
                        .font(.subheadline)
                }
                
                if (!(spot.tags?.isEmpty ?? true)) {
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
            .padding(.leading, 5)
        }
        .onAppear {
            tags = spot.tags?.components(separatedBy: ", ") ?? []
            if (spot.isPublic) {
                scope = "Public"
            } else {
                scope = "Private"
            }
            if (mapViewModel.isAuthorized) {
                calculateDistance()
            }
        }
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let spotLocation = CLLocation(latitude: spot.x, longitude: spot.y)
        let distanceInMeters = userLocation.distance(from: spotLocation)
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
