//
//  DetailView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var mapViewModel: WatchLocationManager
    @State private var away = ""
    let spot: Spot
    
    var body: some View {
        ScrollView {
            Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
                .padding(.vertical)
            Text(spot.name)
            Text(spot.locationName)
            if !spot.locationName.isEmpty {
                HStack {
                    Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                        .font(.system(size: 12))
                    Text(spot.locationName)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
            }
            Text(away)
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                routeMeTo.name = spot.name
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text(spot.name)
                }
            }
        }
        .onAppear {
            away = calculateDistance(x: spot.x, y: spot.y)
        }
    }
    
    private func calculateDistance(x: Double, y: Double) -> String {
        guard let userLocation = mapViewModel.locationManager?.location else { return "" }
        let spotLocation = CLLocation(latitude: x, longitude: y)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            if distanceDouble >= 99 {
                return "99+ km"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " km"
            }
            return String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            if distanceDouble >= 99 {
                return "99+ mi"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " mi"
            }
            return String(format: "%.1f", distanceDouble) + " mi"
        }
        
    }
    
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}
