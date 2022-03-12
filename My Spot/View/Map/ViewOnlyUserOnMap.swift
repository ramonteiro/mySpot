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
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $mapViewModel.region, showsUserLocation: true)
            .ignoresSafeArea()
        }
        .accentColor(.red)
    }
}
