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

struct ViewDiscoverSpots: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var originalRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @Binding var sortBy: String
    @Binding var searchText: String
    @State private var presentDetailsSheet = false
    @State private var presentErrorConnectionAlert = false
    
    var canSearchHere: Bool {
        (spotRegion.center.latitude > originalRegion.center.latitude + 0.01 ||
         spotRegion.center.latitude < originalRegion.center.latitude - 0.01) ||
            (spotRegion.center.longitude > originalRegion.center.longitude + 0.01 ||
             spotRegion.center.longitude < originalRegion.center.longitude - 0.01)
    }
    
    var body: some View {
        map
            .onAppear {
                spotRegion = mapViewModel.searchingHere
                originalRegion = spotRegion
            }
            .fullScreenCover(isPresented: $presentDetailsSheet) {
                DiscoverDetailView(index: selection, canShare: false)
            }
            .alert("Unable To Find New Spots".localized(), isPresented: $presentErrorConnectionAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Connection Error. Please check internet connection and try again.".localized())
            }
    }
    
    // MARK: - Sub Views
    
    private var routeButon: some View {
        Button {
            route()
        } label: {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    private var myLocationButton: some View {
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
    
    private var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    private var map: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.isAuthorized, annotationItems: cloudViewModel.spots, annotationContent: { location in
                MapAnnotation(coordinate: location.location.coordinate) {
                    if (cloudViewModel.spots.count > 0 && cloudViewModel.spots.count >= selection + 1) {
                        MapAnnotationDiscover(spot: location, isSelected: cloudViewModel.spots[selection] == location, color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                            .scaleEffect(cloudViewModel.spots[selection] == location ? 1.2 : 0.9)
                            .shadow(color: Color.black.opacity(0.3), radius: 5)
                            .onTapGesture {
                                selection = cloudViewModel.spots.firstIndex(of: location) ?? 0
                                withAnimation {
                                    setSpotRegion()
                                }
                            }
                    }
                }
            })
            .ignoresSafeArea()
            buttonOverlay
        }
    }
    
    private var leftSide: some View {
        VStack {
            backButton
            Spacer()
        }
    }
    
    private var rightSide: some View {
        VStack {
            myLocationButton
            routeButon
            Spacer()
        }
    }
    
    private var searchHereButton: some View {
        VStack {
            if canSearchHere {
                searchButton
                    .transition(.opacity.animation(.easeInOut(duration: 0.6)))
                Spacer()
            }
        }
    }
    
    private var topRow: some View {
        HStack {
            leftSide
            Spacer()
            searchHereButton
            Spacer()
            rightSide
        }
        .padding()
    }
    
    private var spotPreview: some View {
        TabView(selection: $selection) {
            ForEach(cloudViewModel.spots.indices, id: \.self) { index in
                DiscoverMapPreview(spot: cloudViewModel.spots[index])
                    .tag(index)
                    .onTapGesture {
                        presentDetailsSheet.toggle()
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: UIScreen.screenHeight * 0.25)
        .onChange(of: selection) { _ in
            withAnimation {
                setSpotRegion()
            }
        }
    }
    
    private var buttonOverlay: some View {
        VStack {
            topRow
            Spacer()
            spotPreview
        }
    }
    
    private var searchButton: some View {
        Button {
            Task {
                await search()
            }
        } label: {
            Text("Search Here".localized())
        }
        .disabled(cloudViewModel.isFetching)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .buttonStyle(.borderedProminent)
    }
    
    // MARK: - Functions
    
    private func route() {
        if (cloudViewModel.spots.count > 0 && cloudViewModel.spots.count >= selection + 1) {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.spots[selection].location.coordinate))
            routeMeTo.name = cloudViewModel.spots[selection].name
            routeMeTo.openInMaps(launchOptions: nil)
        }
    }
    
    private func setSpotRegion() {
        spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }
    
    private func search() async {
        do {
            sortBy = "Closest".localized()
            UserDefaults.standard.set(sortBy, forKey: "savedSort")
            try await cloudViewModel.fetchSpotPublic(userLocation: CLLocation(latitude: spotRegion.center.latitude, longitude: spotRegion.center.longitude), filteringBy: sortBy, search: searchText)
            originalRegion = spotRegion
            mapViewModel.searchingHere = spotRegion
        } catch {
            presentErrorConnectionAlert = true
        }
    }
}
