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
    @State private var spotRegion = DefaultLocations.region
    
    var body: some View {
        Map(coordinateRegion: $spotRegion, interactionModes: [], showsUserLocation: ((mapViewModel.locationManager!.authorizationStatus == .authorizedWhenInUse || mapViewModel.locationManager!.authorizationStatus == .authorizedAlways) ? true : false), annotationItems: singlePin) { location in
            MapMarker(coordinate: singlePin[0].coordinate, tint: .red)
        }
        .onAppear {
            spotRegion = MKCoordinateRegion(center: singlePin[0].coordinate, span: DefaultLocations.spanClose)
        }
    }
}
