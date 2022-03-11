//
//  ViewSingleSpotOnMap.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/23/22.
//

/*
 ViewSingleSpotOnMap:
 displays only one spot pin; and user location if it is enabled
 */

import SwiftUI
import MapKit

struct SinglePin: Identifiable {
    let id = UUID()
    var name: String
    var coordinate: CLLocationCoordinate2D
}

struct ViewSingleSpotOnMap: View {
    
    @StateObject var mapViewModel: MapViewModel
    @State var singlePin: [SinglePin]
    
    var body: some View {
        Map(coordinateRegion: .constant(MKCoordinateRegion(center: singlePin[0].coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))), interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.getIsAuthorized(), annotationItems: singlePin) { location in
            MapMarker(coordinate: singlePin[0].coordinate, tint: .red)
        }
    }
}
