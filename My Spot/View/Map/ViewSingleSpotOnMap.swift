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
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @State var singlePin: [SinglePin]
    @State private var spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion,
                interactionModes: [.pan, .zoom],
                showsUserLocation: mapViewModel.isAuthorized,
                annotationItems: singlePin) { location in
                MapMarker(coordinate: singlePin[0].coordinate,
                          tint: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            }
            locationButton
        }
        .onAppear {
            spotRegion = MKCoordinateRegion(center: singlePin[0].coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private var locationButton: some View {
        HStack {
            Spacer()
            VStack {
                displayLocationButton
                Spacer()
            }
        }
    }
    
    private var displayLocationButton: some View {
        Button {
            withAnimation {
                spotRegion = MKCoordinateRegion(center: singlePin[0].coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            }
        } label: {
            Image(systemName: "mappin").imageScale(.large)
        }
        .padding([.top, .trailing])
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
}
