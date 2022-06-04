//
//  ViewDiscoverSpots.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 ViewDiscoverSpots:
 Displays map for discover tab
 */

import SwiftUI
import MapKit
import Combine
import CoreData

struct ViewDiscoverSpots: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var originalRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var showingDetailsSheet = false
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @Binding var sortBy: String
    @Binding var searchText: String
    @State private var showingErrorConnection = false
    
    var body: some View {
        displayMap
            .onAppear {
                spotRegion = mapViewModel.searchingHere
                originalRegion = spotRegion
            }
            .alert("Unable To Find New Spots".localized(), isPresented: $showingErrorConnection) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Connection Error. Please check internet connection and try again.".localized())
            }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var displayRouteButon: some View {
        Button {
            if (cloudViewModel.spots.count > 0 && cloudViewModel.spots.count >= selection + 1) {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.spots[selection].location.coordinate))
                routeMeTo.name = cloudViewModel.spots[selection].name
                routeMeTo.openInMaps(launchOptions: nil)
            }
        } label: {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMyLocationButton: some View {
        Button {
            withAnimation {
                spotRegion = mapViewModel.region
            }
        } label: {
            Image(systemName: "location").imageScale(.large)
        }
        .disabled(!mapViewModel.isAuthorized)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayBackButton: some View {
        Button(action: close ) {
            Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMap: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.getIsAuthorized(), annotationItems: cloudViewModel.spots, annotationContent: { location in
                MapAnnotation(coordinate: location.location.coordinate) {
                    if (cloudViewModel.spots.count > 0 && cloudViewModel.spots.count >= selection + 1) {
                        MapAnnotationDiscover(spot: location, isSelected: cloudViewModel.spots[selection] == location, color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                            .scaleEffect(cloudViewModel.spots[selection] == location ? 1.2 : 0.9)
                            .shadow(color: Color.black.opacity(0.3), radius: 5)
                            .onTapGesture {
                                selection = cloudViewModel.spots.firstIndex(of: location) ?? 0
                                withAnimation {
                                    spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                                }
                            }
                    }
                }
            })
            .ignoresSafeArea()
            VStack {
                HStack {
                    VStack(spacing: 0) {
                        displayBackButton
                        Spacer()
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        if ((spotRegion.center.latitude > originalRegion.center.latitude + 0.01 || spotRegion.center.latitude < originalRegion.center.latitude - 0.01) ||
                            (spotRegion.center.longitude > originalRegion.center.longitude + 0.01 || spotRegion.center.longitude < originalRegion.center.longitude - 0.01)) {
                            displaySearchButton
                                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        displayMyLocationButton
                        displayRouteButon
                        Spacer()
                    }
                }
                .padding()
                Spacer()
                
                TabView(selection: $selection) {
                    ForEach(cloudViewModel.spots.indices, id: \.self) { index in
                        DiscoverMapPreview(spot: cloudViewModel.spots[index])
                            .tag(index)
                            .onTapGesture {
                                showingDetailsSheet.toggle()
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: UIScreen.screenHeight * 0.25)
                .onChange(of: selection) { _ in
                    withAnimation {
                        spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingDetailsSheet) {
            DiscoverDetailView(index: selection, canShare: false)
        }
    }
    
    private var displaySearchButton: some View {
        Button {
            Task {
                do {
                    sortBy = "Closest".localized()
                    UserDefaults.standard.set(sortBy, forKey: "savedSort")
                    try await cloudViewModel.fetchSpotPublic(userLocation: CLLocation(latitude: spotRegion.center.latitude, longitude: spotRegion.center.longitude), filteringBy: sortBy, search: searchText)
                    originalRegion = spotRegion
                    mapViewModel.searchingHere = spotRegion
                } catch {
                    showingErrorConnection = true
                }
            }
        } label: {
            Text("Search Here".localized())
        }
        .disabled(cloudViewModel.isFetching)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
}
