//
//  ShowMapView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/22/22.
//

/*
 ViewOnlyUserOnMap:
 displays map centered on user location and only displays user location
 */

import SwiftUI
import MapKit

struct ViewOnlyUserOnMap: View {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @State private var spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion, showsUserLocation: true)
                .ignoresSafeArea()
            HStack {
                Spacer()
                VStack {
                    displayMyLocationButton
                    Spacer()
                }
            }
        }
        .onAppear {
            spotRegion = mapViewModel.region
        }
    }
    
    private var displayMyLocationButton: some View {
        Button {
            withAnimation {
                spotRegion = mapViewModel.region
            }
        } label: {
            Image(systemName: "location").imageScale(.large)
        }
        .padding([.top, .trailing])
        .disabled(!mapViewModel.isAuthorized)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
}
