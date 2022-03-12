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
import Network
import MapKit

struct DiscoverView: View {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var tabController: TabController
    
    @State private var hasInternet = true
    @State private var showingMapSheet = false
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var searchLocationName = ""
    @State private var sortBy = "Sort By: Closest"
    
    let monitor = NWPathMonitor()
    
    // find spot names from db that contain searchtext
    private var searchResults: [SpotFromCloud] {
            if searchText.isEmpty {
                return cloudViewModel.spots
            } else {
                return cloudViewModel.spots.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.type.lowercased().contains(searchText.lowercased()) || $0.founder.lowercased().contains(searchText.lowercased()) || $0.emoji.contains(searchText)}
            }
        }
    
    var body: some View {
        NavigationView {
            if (hasInternet) {
                if (cloudViewModel.isSignedInToiCloud) {
                displaySpotsFromDB
                } else {
                    displaySignInToIcloudPrompt
                        .navigationTitle("Discover Spots")
                }
            } else {
                Text("No Internet Connection Found")
                    .navigationTitle("Discover Spots")
            }
        }
        .accentColor(.red)
        .onAppear {
            checkForInternetConnection()
            mapViewModel.searchingHere = mapViewModel.region
            if (cloudViewModel.spots.count == 0) {
                loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
            }
            mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                searchLocationName = location
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
    }
    
    private func checkForInternetConnection() {
        monitor.pathUpdateHandler = { path in
            if path.status != .satisfied {
                hasInternet = false
            } else {
                hasInternet = true
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    private func loadSpotsFromDB(location: CLLocation) {
        if (cloudViewModel.spots.count == 0) {
            isLoading = true
        }
        DispatchQueue.main.async {
            cloudViewModel.fetchSpotPublic(userLocation: location, type: "none")
        }
    }
    
    private var displaySpotsFromDB: some View {
        ZStack {
            listSpots
                .navigationTitle("Discover Spots")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        HStack {
                            Button {
                                mapViewModel.checkLocationAuthorization()
                                loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                                
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            
                            Button(action: {
                                showingMapSheet.toggle()
                            }) {
                                Image(systemName: "map").imageScale(.large)
                            }
                            .sheet(isPresented: $showingMapSheet, content: { ViewDiscoverSpots() })
                        }
                    }
                }
            if (isLoading) {
                ZStack {
                    ProgressView("Loading Spots")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
                .onChange(of: cloudViewModel.spots.count) { newValue in
                    isLoading = false
                }
            }
        }
    }
    
    private var listSpots: some View {
        ScrollViewReader { prox in
                List {
                ForEach(searchResults, id: \.self) { spot in
                    NavigationLink(destination: DiscoverDetailView(spot: spot)) {
                        DiscoverRow(spot: spot)
                            .id(spot)
                    }
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
    }
    
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
}
