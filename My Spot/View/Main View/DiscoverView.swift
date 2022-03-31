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
        .navigationViewStyle(.stack)
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
            if (cloudViewModel.spots.count == 0 || cloudViewModel.isFetching) {
                ZStack {
                    ProgressView("Loading Spots")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            } else if (cloudViewModel.spots.count == 0 && !cloudViewModel.isFetching) {
                Text("iCloud servers are currently down.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
            }
        }
    }
    
    private var listSpots: some View {
        ScrollViewReader { prox in
            List {
                ForEach(searchResults.indices, id: \.self) { index in
                    NavigationLink(destination: DiscoverDetailView(index: index, canShare: true)) {
                        DiscoverRow(spot: searchResults[index])
                            .id(searchResults[index])
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
                        prox.scrollTo(searchResults[0])
                    }
                }
            }
            .animation(.default, value: searchResults)
            .searchable(text: $searchText, prompt: "Search \(searchLocationName)")
            .onChange(of: mapViewModel.searchingHere.center.longitude) { _ in
                mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                    searchLocationName = location
                }
            }
        }
        .navigationTitle("Discover")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        cloudViewModel.maxTotalfetches = 10
                        UserDefaults.standard.set(10, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 10 Spots")
                    }
                    Button {
                        cloudViewModel.maxTotalfetches = 20
                        UserDefaults.standard.set(20, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 20 Spots")
                    }
                    Button {
                        cloudViewModel.maxTotalfetches = 30
                        UserDefaults.standard.set(30, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 30 Spots")
                    }
                    Button {
                        cloudViewModel.maxTotalfetches = 40
                        UserDefaults.standard.set(40, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 40 Spots")
                    }
                    Button {
                        cloudViewModel.maxTotalfetches = 50
                        UserDefaults.standard.set(50, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 50 Spots")
                    }
                    Button {
                        cloudViewModel.maxTotalfetches = 100
                        UserDefaults.standard.set(100, forKey: "maxTotalFetches")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude))
                    } label: {
                        Text("Load 100 Spots")
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                        Text("\(cloudViewModel.maxTotalfetches)")
                    }
                }

                Button{
                    showingMapSheet.toggle()
                } label: {
                    Image(systemName: "map").imageScale(.large)
                }
                .fullScreenCover(isPresented: $showingMapSheet) {
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
                Text("Sort By Likes")
            }
            Button {
                sortClosest()
            } label: {
                Text("Sort By Closest")
            }
            Button {
                sortDate()
            } label: {
                Text("Sort By Newest")
            }
            Button {
                sortName()
            } label: {
                Text("Sort By Name")
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
        dateFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
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
