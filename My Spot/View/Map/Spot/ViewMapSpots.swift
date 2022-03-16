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
    @EnvironmentObject var networkViewModel: NetworkMonitor
    @State private var selection = 0
    @State private var transIn: Edge = .leading
    @State private var transOut: Edge = .bottom
    @State private var showingDetailsSheet = false
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

    var body: some View {
        ZStack {
            if (networkViewModel.hasInternet) {
                displayMap
                    .onAppear {
                        withAnimation {
                            spotRegion = mapViewModel.region
                        }
                    }
            } else {
                Text("No Internet Connection Found")
            }
        }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func increaseSelection() {
        if spots.count == selection+1 {
            selection = 0
        } else {
            selection+=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private func decreaseSelection() {
        if 0 > selection-1 {
            selection = spots.count-1
        } else {
            selection-=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private var displayRouteButon: some View {
        Button(action: {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y)))
            routeMeTo.name = spots[selection].name!
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
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.getIsAuthorized(), annotationItems: spots, annotationContent: { location in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: location.x, longitude: location.y)) {
                    MapAnnotationView(spot: location)
                        .scaleEffect(spots[selection] == location ? 1.2 : 0.9)
                        .shadow(radius: 8)
                        .onTapGesture {
                            transIn = .bottom
                            transOut = .bottom
                            selection = spots.firstIndex(of: location) ?? 0
                            withAnimation {
                                spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spots[selection].x, longitude: spots[selection].y), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
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
                    ForEach(spots) { spot in
                        if (spot == spots[selection]) {
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
            DetailsSheet(spot: spots[selection])
        }
    }
}
