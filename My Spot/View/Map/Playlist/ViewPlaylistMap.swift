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
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @ObservedObject var playlist: Playlist
    @State private var selection = 0
    @State private var transIn: Edge = .leading
    @State private var transOut: Edge = .bottom
    @State private var showingDetailsSheet = false
    @State private var filteredSpots: [Spot] = []
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    let isShared: Bool
    
    var body: some View {
        ZStack {
            displayMap
        }
        .onAppear {
            spotRegion = mapViewModel.region
            if isShared {
                filteredSpots = playlist.spotArr.filter{ spot in
                    spot.isShared
                }
            } else {
                filteredSpots = playlist.spotArr
            }
        }
    }
    
    private func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var displayRouteButon: some View {
        Button {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: filteredSpots[selection].x, longitude: filteredSpots[selection].y)))
            routeMeTo.name = filteredSpots[selection].name ?? "Spot"
            routeMeTo.openInMaps(launchOptions: nil)
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
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.isAuthorized, annotationItems: filteredSpots, annotationContent: { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.x, longitude: location.y)) {
                    MapAnnotationView(color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex], spot: location, isSelected: filteredSpots[selection] == location)
                        .scaleEffect(filteredSpots[selection] == location ? 1.2 : 0.9)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                        .onTapGesture {
                            selection = filteredSpots.firstIndex(of: location) ?? 0
                            withAnimation {
                                spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: filteredSpots[selection].x, longitude: filteredSpots[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
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
                    TabView(selection: $selection) {
                        ForEach(filteredSpots.indices, id: \.self) { index in
                            SpotMapPreview(spot: filteredSpots[index])
                                .tag(index)
                                .onTapGesture {
                                    showingDetailsSheet.toggle()
                                }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.screenHeight * 0.25)
                }
                .onChange(of: selection) { _ in
                    withAnimation {
                        spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: filteredSpots[selection].x, longitude: filteredSpots[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingDetailsSheet) {
            DetailView(canShare: false, fromPlaylist: true, spot: filteredSpots[selection], canEdit: true)
        }
    }
}
