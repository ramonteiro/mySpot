//
//  DiscoverView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 DiscoverView:
 root of tabbar for discover, shows all spots from db
 */

import SwiftUI
import MapKit

struct DiscoverView: View {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var networkViewModel: NetworkMonitor
    
    @State private var showingMapSheet = false
    @State private var searchText = ""
    @State private var searchLocationName = ""

    // find spot names from db that contain searchtext
    private var searchResults: [SpotFromCloud] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return cloudViewModel.spots
        } else {
            return cloudViewModel.spots.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.type.lowercased().contains(searchText.lowercased()) || $0.founder.lowercased().contains(searchText.lowercased()) || $0.emoji.contains(searchText)}
        }
    }
    
    var body: some View {
        NavigationView {
            if (networkViewModel.hasInternet && cloudViewModel.isSignedInToiCloud) {
                displaySpotsFromDB
            } else {
                displayError
            }
        }
        .navigationTitle("Discover Spots")
        .onAppear {
            mapViewModel.searchingHere = mapViewModel.region
            if (cloudViewModel.spots.count == 0) {
                loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
            }
            mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                searchLocationName = location
            }
        }
    }
    
    private var displayError: some View {
        ZStack {
            if (!networkViewModel.hasInternet) {
                Text("No Internet Connection Found")
            } else if (!cloudViewModel.isSignedInToiCloud) {
                displaySignInToIcloudPrompt
            }
        }
    }
    
    private var displaySignInToIcloudPrompt: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("You Must Be Signed In To Icloud To Disover And Share Spots")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)")
                        })
                    }
                } label: {
                    Text("Please Sign In Or Create An Account In Settings").font(.subheadline).foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
        }
        .navigationTitle("Discover Spots")
    }
    
    private func loadSpotsFromDB(location: CLLocation) {
        DispatchQueue.main.async {
            cloudViewModel.fetchSpotPublic(userLocation: location, type: "none")
        }
    }
    
    private var displaySpotsFromDB: some View {
        ZStack {
            listSpots
            if (cloudViewModel.spots.count == 0) {
                ZStack {
                    ProgressView("Loading Spots")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
        }
    }
    
    private var listSpots: some View {
        ScrollViewReader { prox in
            List {
                ForEach(searchResults.indices, id: \.self) { index in
                    ZStack {
                        NavigationLink(destination: DiscoverDetailView(index: index)) {
                            DiscoverRow(spot: searchResults[index])
                                .id(searchResults[index])
                        }
                    }
                }
            }
            .onAppear {
                cloudViewModel.canRefresh = true
            }
            .if(cloudViewModel.canRefresh && cloudViewModel.spots.count != 0) { view in
                view.refreshable {
                    mapViewModel.checkLocationAuthorization()
                    loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                }
            }
            .onChange(of: tabController.discoverPopToRoot) { _ in
                if (cloudViewModel.spots.count > 0) {
                    withAnimation(.easeInOut) {
                        prox.scrollTo(cloudViewModel.spots[0])
                    }
                }
            }
            .animation(.easeIn, value: searchResults.count)
            .searchable(text: $searchText, prompt: "Search \(searchLocationName)")
            .onChange(of: mapViewModel.searchingHere.center.longitude) { _ in
                mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                    searchLocationName = location
                }
            }
        }
        .navigationTitle("Discover Spots")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingMapSheet.toggle()
                    }) {
                        Image(systemName: "map").imageScale(.large)
                    }
                    .sheet(isPresented: $showingMapSheet, content: { ViewDiscoverSpots() })
            }
        }
    }
    
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
}
