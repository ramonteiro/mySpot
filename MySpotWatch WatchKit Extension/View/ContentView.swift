//
//  ContentView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var mapViewModel: WatchLocationManager
    @State private var distance: Double = 10
    @State private var maxLoad: Double = 10
    @State private var isMetric = false
    @State private var showList = false
    private let range = 5.0...25.0
    
    var body: some View {
        VStack {
            if (mapViewModel.locationManager?.authorizationStatus == .authorizedWhenInUse || mapViewModel.locationManager?.authorizationStatus == .authorizedAlways) {
                ScrollView {
                    HStack {
                        Image(uiImage: UIImage(named: "logo.png")!)
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text(mapViewModel.locationName.isEmpty ? "Finding Location.." : "\(mapViewModel.locationName)")
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.vertical)
                    if (!mapViewModel.locationName.isEmpty) {
                        NavigationLink(isActive: $showList) {
                            ListView(distance: getDistance(), maxLoad: Int(maxLoad), mapViewModel: mapViewModel)
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search")
                            }
                        }
                    }
                    Text("Range: " + (Int(distance) == 25 ? "Anywhere" : "\(Int(distance)) " + (isMetric ? "km" : "mi")))
                        .padding(.vertical)
                    Slider(value: $distance, in: range) {}
                    Text("Find " + "\(Int(maxLoad)) spots")
                        .padding(.vertical)
                    Slider(value: $maxLoad, in: range) {}
                }
            } else {
                Text("No Location Found")
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Please allow My Spot to use location in settings")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
        }
        .onAppear {
            isMetric = getUnits()
            mapViewModel.fetchLocation { location in
                mapViewModel.location = location
                mapViewModel.getPlacmarkOfLocation(location: location) { placeName in
                    mapViewModel.locationName = placeName
                }
            }
        }
    }
    
    private func getDistance() -> Double {
        if Int(distance) == 25 {
            return 0
        } else if isMetric {
            let distanceUnit = Measurement(value: Double(Int(distance)), unit: UnitLength.kilometers)
            let unitMeters = distanceUnit.converted(to: .meters)
            return unitMeters.value
        } else {
            let distanceUnit = Measurement(value: Double(Int(distance)), unit: UnitLength.miles)
            let unitMeters = distanceUnit.converted(to: .meters)
            return unitMeters.value
        }
    }
    
    private func getUnits() -> Bool {
        if ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true {
            return true
        } else {
            return false
        }
    }
}
