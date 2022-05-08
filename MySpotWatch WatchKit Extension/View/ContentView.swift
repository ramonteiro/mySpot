//
//  ContentView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var mapViewModel: WatchLocationManager
    @ObservedObject var watchViewModel: WatchViewModel
    @State private var distance: Double = 10
    @State private var maxLoad: Double = 10
    @State private var isMetric = false
    @State private var showList = false
    private let range = 5.0...25.0
    
    var body: some View {
        VStack {
            if (mapViewModel.locationManager?.authorizationStatus != .denied) {
                ScrollView {
                    HStack {
                        Image(uiImage: UIImage(named: "logo.png")!)
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text(mapViewModel.locationName.isEmpty ? "Near You".localized() : "\(mapViewModel.locationName)")
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.vertical)
                    if (mapViewModel.locationManager!.location != nil) {
                        NavigationLink(isActive: $showList) {
                            ListView(distance: getDistance(), maxLoad: Int(maxLoad), mapViewModel: mapViewModel, watchViewModel: watchViewModel)
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Search ".localized())
                            }
                        }
                    }
                    Text("Range: ".localized() + (Int(distance) == 25 ? "Anywhere".localized() : "\(Int(distance)) " + (isMetric ? "km" : "mi")))
                        .padding(.vertical)
                    Slider(value: $distance, in: range, step: 5) {}
                    Text("Find ".localized() + "\(Int(maxLoad)) spots")
                        .padding(.vertical)
                    Slider(value: $maxLoad, in: range, step: 5) {}
                }
            } else {
                Text("No Location Found".localized())
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Please allow My Spot to use location in settings".localized())
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            }
        }
        .onChange(of: maxLoad) { newValue in
            UserDefaults.standard.set(Int(newValue), forKey: "maxLoad")
        }
        .onChange(of: distance) { newValue in
            UserDefaults.standard.set(Int(newValue), forKey: "distance")
        }
        .onAppear {
            if UserDefaults.standard.valueExists(forKey: "maxLoad") {
                maxLoad = Double(UserDefaults.standard.integer(forKey: "maxLoad"))
                distance = Double(UserDefaults.standard.integer(forKey: "distance"))
            }
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

extension UserDefaults {
    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
