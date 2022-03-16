//
//  DetailView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DetailView:
 navigation link for each spot from core data item in list in root view
 */

import SwiftUI
import MapKit

struct DetailView: View {
    
    var fromPlaylist: Bool
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var networkViewModel: NetworkMonitor
    @ObservedObject var spot:Spot
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabController: TabController
    @State private var showingEditSheet = false
    
    var body: some View {
        displaySpot
            .onChange(of: tabController.playlistPopToRoot) { _ in
                if (fromPlaylist) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onChange(of: tabController.spotPopToRoot) { _ in
                if (!fromPlaylist) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
    
    private var displaySpot: some View {
        ZStack {
            if (isExisting()) {
                Form {
                    Image(uiImage: spot.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                    Text("Found by: \(spot.founder!)\nOn \(spot.date!)\nTag: \(spot.tags!)").font(.subheadline).foregroundColor(.gray)
                    if (spot.isPublic) {
                        HStack {
                            Text("Public").font(.subheadline).foregroundColor(.gray)
                            Image(systemName: "globe").font(.subheadline).foregroundColor(.gray)
                        }
                    }
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
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            showingEditSheet = true
                        }
                        .sheet(isPresented: $showingEditSheet) {
                            SpotEditSheet(spot: spot)
                        }
                        .disabled(!networkViewModel.hasInternet && spot.isPublic && !cloudViewModel.isSignedInToiCloud)
                        .accentColor(.red)
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
    
    private func close() {
        presentationMode.wrappedValue.dismiss()
    }
}
