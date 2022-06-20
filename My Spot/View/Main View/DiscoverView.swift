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
    @State private var presentMapSheet = false
    @State private var searchText = ""
    @State private var searchLocationName = ""
    @State private var sortBy = "Closest".localized()
    @State private var distance = 0
    @State private var hasSearched = false
    @State private var hasError = false
    @State private var isSearching = false
    @State private var scrollToTop = false
    @State private var didDelete = false
    @State private var spots: [SpotFromCloud] = []
    
    var body: some View {
        NavigationView {
            if (cloudViewModel.isSignedInToiCloud) {
                displaySpotsFromDB
            } else {
                SignInToiCloudErrorView()
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            firstSearch()
        }
    }
    
    // MARK: - Sub Views
    
    private var displaySpotsFromDB: some View {
        ZStack {
            listSpots
            if hasError {
                errorLoadingSpots
            }
        }
        .onChange(of: didDelete) { deleted in
            if deleted {
                refreshSpots()
                didDelete = false
            }
        }
        .fullScreenCover(isPresented: $presentMapSheet) {
            MapViewSpots(spots: $spots, sortBy: $sortBy, searchText: searchText)
        }
    }
    
    private var errorLoadingSpots: some View {
        VStack {
            errorLoadingSpotsTitle
            errorLoadingSpotsSubtitle
        }
        .padding(.vertical)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
        .onAppear {
            checkToLoadMoreSpots()
        }
    }
    
    private var errorLoadingSpotsTitle: some View {
        HStack {
            Spacer()
            Text("Unable to load spots".localized())
                .foregroundColor(.gray)
                .font(.headline)
            Spacer()
        }
    }
    
    private var errorLoadingSpotsSubtitle: some View {
        HStack {
            Spacer()
            Text("Try refreshing or checking your internet connection".localized())
                .foregroundColor(.gray)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    private var spotRows: some View {
        ForEach(spots.indices, id: \.self) { i in
            NavigationLink {
                DetailView(isSheet: false, from: Tab.discover, spot: spots[i], didDelete: $didDelete)
            } label: {
                HStack {
                    SpotRow(spot: $spots[i])
                    Spacer()
                }
                .background(Color(uiColor: UIColor.systemBackground))
                .padding(10)
            }
            .buttonStyle(PlainButtonStyle())
            .id(i)
        }
    }
    
    private var paginationCursor: some View {
        GeometryReader { reader -> Color in
            let minY = reader.frame(in: .global).minY
            let height = UIScreen.screenHeight / 1.3
            if minY < height {
                if let cursor = cloudViewModel.cursorMain {
                    Task {
                        let newSpots = await cloudViewModel.fetchMoreSpotsPublic(cursor: cursor, desiredKeys: cloudViewModel.desiredKeys, resultLimit: cloudViewModel.limit)
                        DispatchQueue.main.async {
                            spots += newSpots
                        }
                    }
                }
            }
            return Color.clear
        }
        .listRowBackground(Color.clear)
    }
    
    private var progressSpinner: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    private func listOfSpots(scroll: ScrollViewProxy) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            spotRows
            if cloudViewModel.isFetching {
                progressSpinner
            } else {
                paginationCursor
            }
        }
        .onChange(of: isSearching) { _ in
            refreshSpots()
        }
        .animation(.default, value: spots)
        .onChange(of: mapViewModel.searchingHere.center.longitude) { _ in
            updateLocationName()
        }
        .gesture(DragGesture()
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
        .onChange(of: scrollToTop) { _ in
            scrollToTop(scroll: scroll)
        }
    }
    
    private var listSpots: some View {
        VStack(spacing: 10) {
            DiscoverSearchBar(searchText: $searchText,
                              searching: $isSearching,
                              searchName: $searchLocationName,
                              hasSearched: $hasSearched)
            ScrollViewReader { scroll in
                ScrollView(showsIndicators: false) {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        refreshSpots()
                    }
                    listOfSpots(scroll: scroll)
                }
            }
            .coordinateSpace(name: "pullToRefresh")
        }
        .navigationTitle("Discover".localized())
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                chooseDistanceMenu
                mapButton
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                displayLocationIcon
            }
        }
    }
    
    private var mapButton: some View {
        Button {
            presentMapSheet.toggle()
        } label: {
            Image(systemName: "map").imageScale(.large)
        }
    }
    
    private var distance5Button: some View {
        Button {
            distance = 5
            UserDefaults.standard.set(5, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            if mapViewModel.isMetric {
                Text("Max Range Of 5 Km".localized())
            } else {
                Text("Max Range Of 5 Mi".localized())
            }
        }
    }
    
    private var distance10Button: some View {
        Button {
            distance = 10
            UserDefaults.standard.set(10, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            if mapViewModel.isMetric {
                Text("Max Range Of 10 Km".localized())
            } else {
                Text("Max Range Of 10 Mi".localized())
            }
        }
    }
    
    private var distance25Button: some View {
        Button {
            distance = 25
            UserDefaults.standard.set(25, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            if mapViewModel.isMetric {
                Text("Max Range Of 25 Km".localized())
            } else {
                Text("Max Range Of 25 Mi".localized())
            }
        }
    }
    
    private var distance50Button: some View {
        Button {
            distance = 50
            UserDefaults.standard.set(50, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            if mapViewModel.isMetric {
                Text("Max Range Of 50 Km".localized())
            } else {
                Text("Max Range Of 50 Mi".localized())
            }
        }
    }
    
    private var distance100Button: some View {
        Button {
            distance = 100
            UserDefaults.standard.set(100, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            if mapViewModel.isMetric {
                Text("Max Range Of 100 Km".localized())
            } else {
                Text("Max Range Of 100 Mi".localized())
            }
        }
    }
    
    private var distance0Button: some View {
        Button {
            distance = 0
            UserDefaults.standard.set(0, forKey: "savedDistance")
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
        } label: {
            Text("Anywhere In The World".localized())
        }
    }
    
    private var chooseDistanceMenu: some View {
        Menu {
            distance5Button
            distance10Button
            distance25Button
            distance50Button
            distance100Button
            distance0Button
        } label: {
            distanceMenuTitle
        }
    }
    
    private var distanceMenuTitle: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease")
            if mapViewModel.isMetric {
                if distance == 0 {
                    Text("Any".localized())
                } else {
                    Text("\(distance) Km")
                }
            } else {
                if distance == 0 {
                    Text("Any".localized())
                } else {
                    Text("\(distance) Mi")
                }
            }
        }
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortLikes()
            } label: {
                Text("Sort By Likes".localized())
            }
            Button {
                sortClosest()
            } label: {
                Text("Sort By Closest".localized())
            }
            Button {
                sortDate()
            } label: {
                Text("Sort By Newest".localized())
            }
            Button {
                sortName()
            } label: {
                Text("Sort By Name".localized())
            }
        } label: {
            HStack {
                Image(systemName: "chevron.up.chevron.down")
                Text("\(sortBy)")
            }
        }
    }
    
    // MARK: - Functions
    
    private func firstSearch() {
        mapViewModel.searchingHere = mapViewModel.region
        if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
            sortBy = (UserDefaults.standard.string(forKey: "savedSort") ?? "Closest").localized()
        }
        if (UserDefaults.standard.valueExists(forKey: "savedDistance")) {
            distance = UserDefaults.standard.integer(forKey: "savedDistance")
        }
        if (spots.count == 0) {
            let dis = CGFloat(cloudViewModel.radiusInMeters)
            loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: dis, filteringBy: sortBy)
        }
        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), isPrecise: true) { location in
            searchLocationName = location
        }
    }
    
    private func loadSpotsFromDB(location: CLLocation, radiusInMeters: CGFloat, filteringBy: String) {
        if cloudViewModel.isFetching { return }
        mapViewModel.checkLocationAuthorization()
        if mapViewModel.isMetric {
            let radiusUnit = Measurement(value: radiusInMeters, unit: UnitLength.kilometers)
            let unitMeters = radiusUnit.converted(to: .meters)
            UserDefaults.standard.set(unitMeters.value, forKey: "savedDistance")
        } else {
            let radiusUnit = Measurement(value: radiusInMeters, unit: UnitLength.miles)
            let unitMeters = radiusUnit.converted(to: .meters)
            UserDefaults.standard.set(unitMeters.value, forKey: "savedDistance")
        }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasSearched = true
        } else {
            hasSearched = false
        }
        Task {
            do {
                let newSpots = try await cloudViewModel.fetchSpotPublic(userLocation: location, filteringBy: filteringBy, search: searchText)
                DispatchQueue.main.async {
                    spots = newSpots
                    scrollToTop.toggle()
                }
            } catch {
                cloudViewModel.isFetching = false
                hasError = true
            }
        }
    }
    
    private func sortClosest() {
        sortBy = "Closest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortName() {
        sortBy = "Name".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortDate() {
        sortBy = "Newest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func sortLikes() {
        sortBy = "Likes".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func checkToLoadMoreSpots() {
        if spots.count != 0 {
            withAnimation {
                hasError.toggle()
            }
        }
    }
    
    private func refreshSpots() {
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func updateLocationName() {
        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), isPrecise: true) { location in
            searchLocationName = location
        }
    }
    
    private func scrollToTop(scroll: ScrollViewProxy) {
        if spots.count > 0 {
            withAnimation(.easeInOut(duration: 0.5)) {
                scroll.scrollTo(0, anchor: .top)
            }
        }
    }
}
