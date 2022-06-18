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
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var showingDetailsSheet = false
    @State private var spotsFiltered: [Spot] = []
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

    var body: some View {
        displayMap
            .onAppear {
                spotRegion = mapViewModel.region
                spotsFiltered = spots.filter{ spot in
                    !spot.isShared && (spot.userId == UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") || spot.userId == "" || spot.userId == nil)
                }
            }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var displayRouteButon: some View {
        Button {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spotsFiltered[selection].x, longitude: spotsFiltered[selection].y)))
            routeMeTo.name = spotsFiltered[selection].name ?? "Spot"
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
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.isAuthorized, annotationItems: spotsFiltered, annotationContent: { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.x, longitude: location.y)) {
                    MapAnnotationView(color: cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex], spot: location, isSelected: spotsFiltered[selection] == location)
                        .scaleEffect(spotsFiltered[selection] == location ? 1.2 : 0.9)
                        .shadow(color: Color.black.opacity(0.3), radius: 5)
                        .onTapGesture {
                            selection = spotsFiltered.firstIndex(of: location) ?? 0
                            withAnimation {
                                spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spotsFiltered[selection].x, longitude: spotsFiltered[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
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
                        ForEach(spotsFiltered.indices, id: \.self) { index in
                            SpotMapPreview(spot: spotsFiltered[index])
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
                        spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spotsFiltered[selection].x, longitude: spotsFiltered[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingDetailsSheet) {
            DetailView(canShare: false, fromPlaylist: false, spot: spotsFiltered[selection], canEdit: true)
        }
    }
}
