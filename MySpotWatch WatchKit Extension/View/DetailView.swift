//
//  DetailView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI
import MapKit

struct DetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var mapViewModel: WatchLocationManager
    @ObservedObject var watchViewModel: WatchViewModel
    @State private var away = ""
    let spot: Spot
    @State private var spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ScrollView {
            Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: WKInterfaceDevice.current().screenBounds.size.width - 20)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((colorScheme == .dark ? Color.white : Color.black), lineWidth: 4)
                )
                .padding(.vertical)
            Text(spot.name)
                .font(.headline)
                .fontWeight(.bold)
            if !spot.locationName.isEmpty {
                HStack {
                    Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                        .font(.subheadline)
                    Text(spot.locationName)
                        .font(.subheadline)
                        .lineLimit(1)
                }
            }
            Text(away)
            Map(coordinateRegion: $spotRegion, interactionModes: [], showsUserLocation: false, annotationItems: [SinglePin(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))]) { location in
                MapMarker(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y), tint: .red)
            }
            .frame(width: WKInterfaceDevice.current().screenBounds.size.width - 20, height: WKInterfaceDevice.current().screenBounds.size.width - 20)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke((colorScheme == .dark ? Color.white : Color.black), lineWidth: 4)
            )
            .padding(.vertical)
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                routeMeTo.name = spot.name
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                    Text(spot.name)
                        .font(.subheadline)
                }
            }
            if (watchViewModel.session.isReachable) {
                Button {
                    watchViewModel.sendSpotId(id: spot.spotid)
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 25))
                        Text("Download On iPhone")
                            .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            away = calculateDistance(x: spot.x, y: spot.y)
            spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
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
