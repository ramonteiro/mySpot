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
    @State private var sortBy = "Closest"

    // find spot names from db that contain searchtext
    private var searchResults: [SpotFromCloud] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return cloudViewModel.spots
        } else {
            return cloudViewModel.spots.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.type.lowercased().contains(searchText.lowercased()) || $0.founder.lowercased().contains(searchText.lowercased())}
        }
    }
    
    var body: some View {
        NavigationView {
            // check if user is signed in to icloud/has internet
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
            sortBy = "Closest"
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
                Button{
                    showingMapSheet.toggle()
                } label: {
                    Image(systemName: "map").imageScale(.large)
                }
                .sheet(isPresented: $showingMapSheet) {
                    ViewDiscoverSpots()
                }
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if (!cloudViewModel.isFetching) {
                    displayLocationIcon
                } else {
                    ProgressView()
                }
            }
        }
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortLikes()
            } label: {
                Text("Likes")
            }
            Button {
                sortClosest()
            } label: {
                Text("Closest")
            }
            Button {
                sortDate()
            } label: {
                Text("Newest")
            }
            Button {
                sortName()
            } label: {
                Text("Name")
            }
        } label: {
            HStack {
                Image(systemName: "chevron.up.chevron.down")
                Text("\(sortBy)")
            }
        }
    }
    
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
    
    private func sortClosest() {
        cloudViewModel.spots = cloudViewModel.spots.sorted { (spot1, spot2) -> Bool in
            let distanceFromSpot1 = distanceBetween(x1: mapViewModel.searchingHere.center.latitude, x2: spot1.location.coordinate.latitude, y1: mapViewModel.searchingHere.center.longitude, y2: spot1.location.coordinate.longitude)
            let distanceFromSpot2 = distanceBetween(x1: mapViewModel.searchingHere.center.latitude, x2: spot2.location.coordinate.latitude, y1: mapViewModel.searchingHere.center.longitude, y2: spot2.location.coordinate.longitude)
            return distanceFromSpot1 < distanceFromSpot2
        }
        sortBy = "Closest"
    }
    
    private func sortName() {
        cloudViewModel.spots = cloudViewModel.spots.sorted { (spot1, spot2) -> Bool in
            if (spot1.name < spot2.name) {
                return true
            } else {
                return false
            }
        }
        sortBy = "Name"
    }
    
    private func sortDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        cloudViewModel.spots = cloudViewModel.spots.sorted { (spot1, spot2) -> Bool in
            guard let date1 = dateFormatter.date(from: spot1.date) else { return true }
            guard let date2 = dateFormatter.date(from: spot2.date) else { return true }
            if (date1 > date2) {
                return true
            } else {
                return false
            }
        }
        sortBy = "Newest"
    }
    
    private func sortLikes() {
        cloudViewModel.spots = cloudViewModel.spots.sorted { (spot1, spot2) -> Bool in
            if (spot1.likes > spot2.likes) {
                return true
            } else {
                return false
            }
        }
        sortBy = "Likes"
    }
}
