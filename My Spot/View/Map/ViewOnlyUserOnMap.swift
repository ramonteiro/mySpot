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
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Binding var customLocation: Bool
    @Binding var hasSet: Bool
    @Binding var locationName: String
    @State private var locations = [MKPointAnnotation]()
    @Binding var centerRegion: MKCoordinateRegion
    @State private var spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ZStack {
            if customLocation {
                MapView(centerRegion: $centerRegion, annotations: locations, isForNotifications: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(!hasSet)
                Cross()
                    .stroke(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            } else {
                Map(coordinateRegion: $spotRegion, showsUserLocation: !customLocation)
                    .ignoresSafeArea()
            }
            HStack {
                Spacer()
                VStack {
                    displayMyLocationButton
                    Spacer()
                }
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    displayCustomLocationButton
                    Spacer()
                }
            }
        }
        .onChange(of: hasSet) { newValue in
            if newValue {
                UserDefaults.standard.set(Double(centerRegion.center.longitude), forKey: "tempPinY")
                UserDefaults.standard.set(Double(centerRegion.center.latitude), forKey: "tempPinX")
            }
        }
        .onAppear {
            spotRegion = mapViewModel.region
        }
    }
    
    private var displayCustomLocationButton: some View {
        Button(customLocation ? "My Location".localized() : "Custom Location".localized()) {
            withAnimation {
                customLocation.toggle()
            }
            if !customLocation {
                mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), completionHandler: { location in
                    locationName = location
                })
            }
        }
        .padding(.bottom)
        .buttonStyle(.borderedProminent)
        .disabled(customLocation && !mapViewModel.isAuthorized)
    }
    
    private var displayMyLocationButton: some View {
        Button {
            if !customLocation {
                withAnimation {
                    spotRegion = mapViewModel.region
                }
            } else {
                mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: centerRegion.center.latitude, longitude: centerRegion.center.longitude), completionHandler: { location in
                    locationName = location
                })
                hasSet.toggle()
            }
        } label: {
            if !customLocation {
                Image(systemName: "location").imageScale(.large)
            } else {
                if !hasSet {
                    Text("Save".localized())
                } else {
                    Text("Edit".localized())
                }
            }
        }
        .padding([.top, .trailing])
        .disabled(!mapViewModel.isAuthorized && !customLocation)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
}
