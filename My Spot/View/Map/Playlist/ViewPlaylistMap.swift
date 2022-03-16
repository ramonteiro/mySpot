//
//  ViewPlaylistMap.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 ViewPlaylistMap:
 Displays map for playlist tab
 */

import SwiftUI
import MapKit

struct ViewPlaylistMap: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @ObservedObject var playlist: Playlist
    @State private var selection = 0
    @State private var transIn: Edge = .leading
    @State private var transOut: Edge = .bottom
    @State private var showingDetailsSheet = false
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ZStack {
            displayMap
        }
        .onAppear {
            withAnimation {
                spotRegion = mapViewModel.region
            }
        }
    }
    
    private func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func increaseSelection() {
        if playlist.spotArr.count == selection+1 {
            selection = 0
        } else {
            selection+=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: playlist.spotArr[selection].x, longitude: playlist.spotArr[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private func decreaseSelection() {
        if 0 > selection-1 {
            selection = playlist.spotArr.count-1
        } else {
            selection-=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: playlist.spotArr[selection].x, longitude: playlist.spotArr[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private var displayRouteButon: some View {
        Button(action: {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: playlist.spotArr[selection].x, longitude: playlist.spotArr[selection].y)))
            routeMeTo.name = playlist.spotArr[selection].name!
            routeMeTo.openInMaps(launchOptions: nil)
        }) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMyLocationButton: some View {
        Button(action: {
            withAnimation {
                spotRegion = mapViewModel.region
            }
        }) {
            Image(systemName: "location").imageScale(.large)
        }
        .disabled(!mapViewModel.isAuthorized)
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayBackButton: some View {
        Button(action: close ) {
            Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMap: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.getIsAuthorized(), annotationItems: playlist.spotArr, annotationContent: { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.x, longitude: location.y)) {
                    MapAnnotationView(spot: location)
                        .scaleEffect(playlist.spotArr[selection] == location ? 1.2 : 0.9)
                        .shadow(radius: 8)
                        .onTapGesture {
                            transIn = .bottom
                            transOut = .bottom
                            selection = playlist.spotArr.firstIndex(of: location) ?? 0
                            withAnimation {
                                spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: playlist.spotArr[selection].x, longitude: playlist.spotArr[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
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
                        displayMyLocationButton
                        displayRouteButon
                        Spacer()
                    }
                }
                .padding()
                Spacer()
                
                ZStack {
                    ForEach(playlist.spotArr) { spot in
                        if (spot == playlist.spotArr[selection]) {
                            SpotMapPreview(spot: spot)
                                .shadow(color: Color.black.opacity(0.3), radius: 10)
                                .padding()
                                .onTapGesture {
                                    showingDetailsSheet.toggle()
                                }
                                .transition(.asymmetric(insertion: .move(edge: transIn), removal: .move(edge: transOut)))
                                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                            .onEnded({ value in
                                                withAnimation {
                                                    if value.translation.width < 0 {
                                                        transIn = .trailing
                                                        transOut = .bottom
                                                        increaseSelection()
                                                    }

                                                    if value.translation.width > 0 {
                                                        transIn = .leading
                                                        transOut = .bottom
                                                        decreaseSelection()
                                                    }
                                                }
                                            }))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetailsSheet) {
            DetailsSheet(spot: playlist.spotArr[selection])
        }
    }
}


struct DetailsSheet: View {
    
    var spot: Spot
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                if (isExisting()) {
                    Form {
                        Image(uiImage: spot.image!)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                        Text("Found by: \(spot.founder!)\nOn \(spot.date!)").font(.subheadline).foregroundColor(.gray)
                        Section(header: Text("Description")) {
                            Text(spot.details!)
                        }
                        Section(header: Text("Location")) {
                            ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name!, coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))])
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                            Button("Take Me To \(spot.name!)") {
                                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                                routeMeTo.name = spot.name!
                                routeMeTo.openInMaps(launchOptions: nil)
                            }
                            .accentColor(.blue)
                        }
                    }
                    .navigationTitle(spot.name!)
                    .listRowSeparator(.hidden)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
    }
    
    private func isExisting() -> Bool {
        if let _ = spot.name {
            return true
        } else {
            return false
        }
    }
}

