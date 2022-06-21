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
    @State private var spotRegion = DefaultLocations.region
    
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
                                            span: DefaultLocations.spanClose)
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
                                                span: DefaultLocations.spanClose)
            }
        } label: {
            Image(systemName: "mappin").imageScale(.large)
        }
        .padding([.top, .trailing])
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
}
