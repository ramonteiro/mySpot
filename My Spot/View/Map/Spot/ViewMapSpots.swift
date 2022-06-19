//
//  ViewSpotsSheet.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 ViewMapSpots:
 Displays map for my spots tab
 */

import SwiftUI
import MapKit

struct ViewMapSpots: View {
    
    let spots: [Spot]
    let fromPlaylist: Bool
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var presentDetailsSheet = false
    @State private var spotRegion = DefaultLocations.region

    var body: some View {
        map
            .onAppear {
                spotRegion = mapViewModel.region
            }
    }
    
    // MARK: - Sub Views
    
    private var routeButon: some View {
        Button {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y)))
            routeMeTo.name = spots[selection].name ?? "Spot"
            routeMeTo.openInMaps(launchOptions: nil)
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
    
    private func mapAnnotation(spot: Spot) -> some View {
        SpotMapAnnotation(spot: spot,
                          isSelected: spots[selection] == spot,
                          color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        .scaleEffect(spots[selection] == spot ? 1.2 : 0.9)
        .shadow(color: Color.black.opacity(0.3), radius: 5)
        .onTapGesture {
            selection = spots.firstIndex(of: spot) ?? 0
            withAnimation {
                setNewSpotRegion()
            }
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $spotRegion,
            showsUserLocation: mapViewModel.isAuthorized,
            annotationItems: spots) { spot in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)) {
                mapAnnotation(spot: spot)
            }
        }
        .ignoresSafeArea()
    }
    
    private var map: some View {
        ZStack {
            mapView
            mapOverlay
        }
        .fullScreenCover(isPresented: $presentDetailsSheet) {
            DetailView(canShare: false, fromPlaylist: fromPlaylist, spot: spots[selection], canEdit: true)
        }
    }
    
    private var rightSideButtons: some View {
        VStack {
            myLocationButton
            routeButon
            Spacer()
        }
    }
    
    private var leftSideButton: some View {
        VStack {
            backButton
            Spacer()
        }
    }
    
    private var topButtonRow: some View {
        HStack {
            leftSideButton
            Spacer()
            rightSideButtons
        }
        .padding()
    }
    
    private var mapOverlay: some View {
        VStack {
            topButtonRow
            Spacer()
            spotPreview
            .onChange(of: selection) { _ in
                withAnimation {
                    setNewSpotRegion()
                }
            }
        }
    }
    
    private var spotPreview: some View {
        ZStack {
            TabView(selection: $selection) {
                ForEach(spots.indices, id: \.self) { index in
                    MapSpotPreview(spot: spots[index])
                        .tag(index)
                        .onTapGesture {
                            presentDetailsSheet.toggle()
                        }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.screenHeight * 0.25)
        }
    }
    
    // MARK: - Functions
    
    private func setNewSpotRegion() {
        spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y), span: DefaultLocations.spanClose)
    }
}
