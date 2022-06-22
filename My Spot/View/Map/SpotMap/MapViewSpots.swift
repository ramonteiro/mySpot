//
//  MapViewSpots.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

import SwiftUI
import MapKit

struct MapViewSpots<T: SpotPreviewType>: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var originalRegion = DefaultLocations.region
    @State private var spotRegion = DefaultLocations.region
    @State private var presentDetailsSheet = false
    @State private var presentErrorConnectionAlert = false
    @State private var didDelete = false
    @Binding var spots: [T]
    @Binding var sortBy: String
    let searchText: String?
    
    var canSearchHere: Bool {
        (spotRegion.center.latitude > originalRegion.center.latitude + 0.01 ||
         spotRegion.center.latitude < originalRegion.center.latitude - 0.01) ||
            (spotRegion.center.longitude > originalRegion.center.longitude + 0.01 ||
             spotRegion.center.longitude < originalRegion.center.longitude - 0.01)
    }
    
    var body: some View {
        map
            .onAppear {
                if spots.count > 0 {
                    spotRegion = MKCoordinateRegion(center: spots[0].locationPreview.coordinate, span: DefaultLocations.spanClose)
                } else {
                    spotRegion = mapViewModel.searchingHere
                }
                originalRegion = spotRegion
            }
            .fullScreenCover(isPresented: $presentDetailsSheet) {
                DetailView(isSheet: true,
                           from: (spots[selection].isFromDiscover ? Tab.discover : Tab.spots),
                           spot: spots[selection],
                           didDelete: $didDelete)
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
    
    private func mapAnnotation(spot: T) -> some View {
        SpotMapAnnotation(spot: spot,
                          isSelected: spots[selection] == spot,
                          color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            .scaleEffect(spots[selection] == spot ? 1.2 : 0.9)
            .shadow(color: Color.black.opacity(0.3), radius: 5)
            .onTapGesture {
                selection = spots.firstIndex(of: spot) ?? 0
                withAnimation {
                    setSpotRegion()
                }
            }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $spotRegion, showsUserLocation: mapViewModel.isAuthorized, annotationItems: spots) { spot in
            MapAnnotation(coordinate: spot.locationPreview.coordinate) {
                mapAnnotation(spot: spot)
            }
        }
        .ignoresSafeArea()
    }
    
    private var map: some View {
        ZStack {
            mapView
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
            if spots[selection].isFromDiscover {
                searchHereButton
            }
            Spacer()
            rightSide
        }
        .padding()
    }
    
    private var spotPreview: some View {
        TabView(selection: $selection) {
            ForEach(spots.indices, id: \.self) { i in
                MapSpotPreview(spot: spots[i])
                    .tag(i)
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
        let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: spots[selection].locationPreview.coordinate))
        routeMeTo.name = spots[selection].namePreview
        routeMeTo.openInMaps(launchOptions: nil)
    }
    
    private func setSpotRegion() {
        spotRegion = MKCoordinateRegion(center: spots[selection].locationPreview.coordinate,
                                        span: DefaultLocations.spanClose)
    }
    
    private func search() async {
        do {
            sortBy = "Closest".localized()
            UserDefaults.standard.set(sortBy, forKey: "savedSort")
            let cloudSpots = try await cloudViewModel.fetchSpotPublic(userLocation: CLLocation(latitude: spotRegion.center.latitude, longitude: spotRegion.center.longitude), filteringBy: "Closest".localized(), search: searchText ?? "")
            if let cloudSpots = cloudSpots as? [T] {
                spots = cloudSpots
                print("worked")
            }
            originalRegion = spotRegion
            if spots.count > 0 { selection = 0 }
            mapViewModel.searchingHere = spotRegion
        } catch {
            presentErrorConnectionAlert = true
        }
    }
}
