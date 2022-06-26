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
    @State private var map = MKMapView()
    @State private var mapImageToggle = "square.2.stack.3d.top.filled"
    @State private var centerRegion = MKCoordinateRegion()
    @State private var selectedFromSwipes = false
    @State private var selectedFromTap = false
    @State private var presentDetailsSheet = false
    @State private var presentErrorConnectionAlert = false
    @State private var didDelete = false
    @State private var initialized = false
    @Binding var spots: [T]
    @Binding var sortBy: String
    private let padding: CGFloat = 10
    let searchText: String?
    
    var canSearchHere: Bool {
        (centerRegion.center.latitude > originalRegion.center.latitude + 0.01 ||
         centerRegion.center.latitude < originalRegion.center.latitude - 0.01) ||
            (centerRegion.center.longitude > originalRegion.center.longitude + 0.01 ||
             centerRegion.center.longitude < originalRegion.center.longitude - 0.01)
    }
    
    var body: some View {
        mapOfSpots
            .onAppear {
                if !initialized {
                    if spots.count > 0 {
                        let region = MKCoordinateRegion(center: spots[0].locationPreview.coordinate, span: DefaultLocations.spanClose)
                        map.setRegion(region, animated: true)
                        centerRegion = region
                        originalRegion = region
                    } else {
                        let region = mapViewModel.searchingHere
                        map.setRegion(region, animated: true)
                        centerRegion = region
                        originalRegion = region
                    }
                    originalRegion = centerRegion
                    refreshAnnotations()
                    initialized = true
                }
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
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
        }
    }
    
    private var myLocationButton: some View {
        Button {
            map.setRegion(mapViewModel.region, animated: true)
        } label: {
            Image(systemName: "location")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background { mapViewModel.isAuthorized ? cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] : .gray }
                .clipShape(Circle())
        }
        .disabled(!mapViewModel.isAuthorized)
    }
    
    private var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "arrowshape.turn.up.backward")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
        }
    }
    
    private var mapView: some View {
        MapViewSpotsWithPreview(map: $map,
                                centerRegion: $centerRegion,
                                selectedAnnotation: $selection,
                                spots: $spots,
                                selectedFromSwipes: $selectedFromSwipes,
                                selectedFromTap: $selectedFromTap)
            .ignoresSafeArea()
    }
    
    private var mapOfSpots: some View {
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
        VStack(spacing: padding * 1.5) {
            myLocationButton
            routeButon
            spotLocationButton
            toggleMapTypeButon
            Spacer()
        }
    }
    
    private var spotLocationButton: some View {
        Button {
            locateSpot()
        } label: {
            Image(systemName: "scope")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
        }
    }
    
    private var toggleMapTypeButon: some View {
        Button {
            toggleMapType()
        } label: {
            Image(systemName: mapImageToggle)
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background { cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] }
                .clipShape(Circle())
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
                MapSpotPreview(spot: $spots[i])
                    .tag(i)
                    .onTapGesture {
                        presentDetailsSheet.toggle()
                    }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: UIScreen.screenHeight * 0.25)
        .onChange(of: selection) { _ in
            map.setRegion(MKCoordinateRegion(center: spots[selection].locationPreview.coordinate, span: DefaultLocations.spanClose), animated: true)
            if !selectedFromTap {
                if let annotation = map.annotations.first(where: {
                    $0.coordinate.latitude == spots[selection].locationPreview.coordinate.latitude &&
                    $0.coordinate.longitude == spots[selection].locationPreview.coordinate.longitude &&
                    $0.title == spots[selection].namePreview
                }) {
                    selectedFromSwipes = true
                    map.selectAnnotation(annotation, animated: true)
                }
            } else {
                selectedFromTap = false
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
                .foregroundColor(.white)
                .padding(padding)
                .frame(height: 50)
                .background { !cloudViewModel.isFetching ? cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] : .gray }
                .clipShape(Capsule())
        }
        .disabled(cloudViewModel.isFetching)
    }
    
    // MARK: - Functions
    
    private func route() {
        if selection >= spots.count { return }
        let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: spots[selection].locationPreview.coordinate))
        routeMeTo.name = spots[selection].namePreview
        routeMeTo.openInMaps(launchOptions: nil)
    }
    
    private func search() async {
        do {
            sortBy = "Closest".localized()
            UserDefaults.standard.set(sortBy, forKey: "savedSort")
            let cloudSpots = try await cloudViewModel.fetchSpotPublic(userLocation: CLLocation(latitude: centerRegion.center.latitude, longitude: centerRegion.center.longitude), filteringBy: "Closest".localized(), search: searchText ?? "")
            if let cloudSpots = cloudSpots as? [T] {
                spots = cloudSpots
            }
            refreshAnnotations()
            originalRegion = centerRegion
            mapViewModel.searchingHere = centerRegion
        } catch {
            presentErrorConnectionAlert = true
        }
    }
    
    private func refreshAnnotations() {
        var annotations: [MKPointAnnotation] = []
        spots.forEach { spot in
            let annotation = MKPointAnnotation()
            annotation.coordinate = spot.locationPreview.coordinate
            annotation.title = spot.namePreview
            annotations.append(annotation)
        }
        let oldAnnotations = map.annotations
        map.removeAnnotations(oldAnnotations)
        map.addAnnotations(annotations)
    }
    
    private func toggleMapType() {
        if map.mapType == .standard {
            map.mapType = .hybrid
            withAnimation {
                mapImageToggle = "square.2.stack.3d.bottom.filled"
            }
        } else {
            map.mapType = .standard
            withAnimation {
                mapImageToggle = "square.2.stack.3d.top.filled"
            }
        }
    }
    
    private func locateSpot() {
        if selection >= spots.count { return }
        map.setRegion(MKCoordinateRegion(center: spots[selection].locationPreview.coordinate, span: DefaultLocations.spanClose), animated: true)
    }
}
