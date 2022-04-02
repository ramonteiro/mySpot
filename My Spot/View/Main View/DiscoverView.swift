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
    
    @State private var showingMapSheet = false
    @State private var searchText = ""
    @State private var searchLocationName = ""
    @State private var sortBy = "Closest"
    @State private var distance = 0
    @State private var isMetric = false
    @State private var hasError = false
    @State private var searching = false
    @State private var canLoad = false
    
    var body: some View {
        NavigationView {
            // check if user is signed in to icloud/has internet
            if (cloudViewModel.isSignedInToiCloud) {
                displaySpotsFromDB
            } else {
                displaySignInToIcloudPrompt
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            mapViewModel.searchingHere = mapViewModel.region
            if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
                sortBy = UserDefaults.standard.string(forKey: "savedSort") ?? "Closest"
            }
            if (UserDefaults.standard.valueExists(forKey: "savedDistance")) {
                distance = UserDefaults.standard.integer(forKey: "savedDistance")
            }
            if (cloudViewModel.spots.count == 0) {
                let dis = CGFloat(cloudViewModel.radiusInMeters)
                loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: dis, filteringBy: sortBy)
            }
            mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                searchLocationName = location
            }
            isMetric = getIsMetric()
        }
    }
    
    private func getIsMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
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
    
    private func loadSpotsFromDB(location: CLLocation, radiusInMeters: CGFloat, filteringBy: String) {
        if isMetric {
            let radiusUnit = Measurement(value: radiusInMeters, unit: UnitLength.kilometers)
            let unitMeters = radiusUnit.converted(to: .meters)
            cloudViewModel.radiusInMeters = unitMeters.value
        } else {
            let radiusUnit = Measurement(value: radiusInMeters, unit: UnitLength.miles)
            let unitMeters = radiusUnit.converted(to: .meters)
            cloudViewModel.radiusInMeters = unitMeters.value
        }
        Task {
            do {
                try await cloudViewModel.fetchSpotPublic(userLocation: location, filteringBy: filteringBy, search: searchText)
            } catch {
                cloudViewModel.isFetching = false
                hasError = true
            }
        }
    }
    
    private var displaySpotsFromDB: some View {
        ZStack {
            listSpots
            if (cloudViewModel.isFetching) {
                ZStack {
                    ProgressView("Loading Spots")
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
            if hasError {
                VStack {
                    HStack {
                        Spacer()
                        Text("Unable to load spots")
                            .foregroundColor(.gray)
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Try refreshing or checking your internet connection")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                )
                .onAppear {
                    if cloudViewModel.spots.count != 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hasError.toggle()
                        }
                    }
                }
            }
        }
    }
    
    private var listSpots: some View {
        ScrollViewReader { prox in
            VStack(spacing: 10) {
                SearchBar(searchText: $searchText, searching: $searching, searchName: $searchLocationName)
                List {
                    ForEach(cloudViewModel.spots.indices, id: \.self) { index in
                        NavigationLink(destination: DiscoverDetailView(index: index, canShare: true)) {
                            DiscoverRow(spot: cloudViewModel.spots[index])
                                .id(cloudViewModel.spots[index])
                        }
                    }
                    if (canLoad) {
                        loadMoreSpots
                            .listRowBackground(Color.clear)
                    }
                }
                .gesture(DragGesture()
                    .onChanged { _ in
                        UIApplication.shared.dismissKeyboard()
                    }
                )
                .onChange(of: cloudViewModel.isFetching) { fetching in
                    if fetching {
                        withAnimation {
                            canLoad = false
                        }
                    } else if let _ = cloudViewModel.cursorMain {
                        withAnimation {
                            canLoad = true
                        }
                    }
                }
                .onAppear {
                    cloudViewModel.canRefresh = true
                }
                .onChange(of: searching) { _ in
                    loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                }
                .if(cloudViewModel.canRefresh) { view in
                    view.refreshable {
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    }
                }
                .onChange(of: tabController.discoverPopToRoot) { _ in
                    if (cloudViewModel.spots.count > 0) {
                        withAnimation(.easeInOut) {
                            prox.scrollTo(cloudViewModel.spots[0])
                        }
                    }
                }
                .animation(.default, value: cloudViewModel.spots)
                .onChange(of: mapViewModel.searchingHere.center.longitude) { _ in
                    mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude)) { location in
                        searchLocationName = location
                    }
                }
            }
        }
        .navigationTitle("Discover")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        distance = 5
                        UserDefaults.standard.set(5, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        if isMetric {
                            Text("Max Range Of 5 Km")
                        } else {
                            Text("Max Range Of 5 Mi")
                        }
                    }
                    Button {
                        distance = 10
                        UserDefaults.standard.set(10, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        if isMetric {
                            Text("Max Range Of 10 Km")
                        } else {
                            Text("Max Range Of 10 Mi")
                        }
                    }
                    Button {
                        distance = 25
                        UserDefaults.standard.set(25, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        if isMetric {
                            Text("Max Range Of 25 Km")
                        } else {
                            Text("Max Range Of 25 Mi")
                        }
                    }
                    Button {
                        distance = 50
                        UserDefaults.standard.set(50, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        if isMetric {
                            Text("Max Range Of 50 Km")
                        } else {
                            Text("Max Range Of 50 Mi")
                        }
                    }
                    Button {
                        distance = 100
                        UserDefaults.standard.set(100, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        if isMetric {
                            Text("Max Range Of 100 Km")
                        } else {
                            Text("Max Range Of 100 Mi")
                        }
                    }
                    Button {
                        distance = 0
                        UserDefaults.standard.set(0, forKey: "savedDistance")
                        mapViewModel.checkLocationAuthorization()
                        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
                    } label: {
                        Text("Anywhere In The World")
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                        if isMetric {
                            if distance == 0 {
                                Text("Any")
                            } else {
                                Text("\(distance) Km")
                            }
                        } else {
                            if distance == 0 {
                                Text("Any")
                            } else {
                                Text("\(distance) Mi")
                            }
                        }
                    }
                }

                Button{
                    showingMapSheet.toggle()
                } label: {
                    Image(systemName: "map").imageScale(.large)
                }
                .fullScreenCover(isPresented: $showingMapSheet) {
                    ViewDiscoverSpots(sortBy: $sortBy, searchText: $searchText)
                }
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                displayLocationIcon
            }
        }
    }
    
    private var loadMoreSpots: some View {
        HStack {
            Spacer()
            Text("Load More Spots")
                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            Spacer()
        }
        .onTapGesture {
            if let cursor = cloudViewModel.cursorMain {
                Task {
                    await cloudViewModel.fetchMoreSpotsPublic(cursor: cursor, desiredKeys: cloudViewModel.desiredKeys, resultLimit: 20)
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
    
    private func sortClosest() {
        sortBy = "Closest"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortName() {
        sortBy = "Name"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortDate() {
        sortBy = "Newest"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortLikes() {
        sortBy = "Likes"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
}


struct SearchBar: View {
    
    @Binding var searchText: String
    @Binding var searching: Bool
    @Binding var searchName: String
    @State private var canCancel: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search \(searchName)", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            searching.toggle()
                        }
                    }
                if (canCancel) {
                    Spacer()
                    Image(systemName: "xmark")
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .onTapGesture {
                            UIApplication.shared.dismissKeyboard()
                            searchText = ""
                            searching.toggle()
                        }
                        .padding(.trailing, 13)
                }
            }
            .foregroundColor(.gray)
            .padding(.leading, 13)
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding(.horizontal)
        .onChange(of: searchText) { newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation {
                    canCancel = true
                }
            } else {
                withAnimation {
                    canCancel = false
                }
            }
        }
    }
}
