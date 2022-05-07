//
//  MapView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/7/22.
//
//

import SwiftUI
import MapKit

struct SinglePin: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

struct ViewSingleSpotOnMap: View {
    
    @ObservedObject var mapViewModel: WatchLocationManager
    @State var singlePin: [SinglePin]
    @State private var spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        Map(coordinateRegion: $spotRegion, interactionModes: [], showsUserLocation: ((mapViewModel.locationManager!.authorizationStatus == .authorizedWhenInUse || mapViewModel.locationManager!.authorizationStatus == .authorizedAlways) ? true : false), annotationItems: singlePin) { location in
            MapMarker(coordinate: singlePin[0].coordinate, tint: .red)
        }
        .onAppear {
            spotRegion = MKCoordinateRegion(center: singlePin[0].coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
}
