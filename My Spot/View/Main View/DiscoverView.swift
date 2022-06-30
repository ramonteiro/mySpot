import SwiftUI
import MapKit
import AlertToast

struct DiscoverView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var tabController: TabController
    @State private var presentMapSheet = false
    @State private var searchText = ""
    @State private var searchLocationName = ""
    @State private var sortBy = "Closest".localized()
    @State private var distance = 0
    @State private var hasSearched = false
    @State private var hasSearchedUsers = false
    @State private var hasError = false
    @State private var isSearching = false
    @State private var scrollToTop = false
    @State private var didDelete = false
    @State private var spots: [SpotFromCloud] = []
    @State private var users: [AccountModel] = []
    @State private var isSearchingUsers = false
    @State private var isFetchingUsers = false
    @State private var scrollToTopUsers = false
    @State private var showUserSearch = 0
    @State private var searchTextUsers = ""
    @State private var usersSearchText = "Users".localized()
    @State private var selectedAccount: AccountModel?
    let tabs = ["Users".localized(), "Spots"]
    @Namespace var animation
    
    var body: some View {
        NavigationView {
            if (cloudViewModel.isSignedInToiCloud) {
                displaySpotsFromDB
                    .animation(.default, value: showUserSearch)
            } else {
                SignInToiCloudErrorView()
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            firstSearch()
        }
        .toast(isPresenting: $didDelete) {
            AlertToast(displayMode: .alert, type: .systemImage("exclamationmark.triangle", .yellow), title: "Spot Deleted".localized())
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
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    NavigationLink {
                        DetailView(isSheet: false, from: Tab.discover, spot: spots[i], didDelete: $didDelete)
                    } label: {
                        MapSpotPreview(spot: $spots[i])
                    }
                    .buttonStyle(ScaleButtonStyle())
                    Spacer()
                }
                .id(i)
                if i != spots.count - 1 {
                    Divider()
                        .padding()
                }
            }
        }
    }
    
    private var userRows: some View {
        ForEach(users.indices, id: \.self) { i in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        selectedAccount = users[i]
                    } label: {
                        HStack {
                            AccountRow(account: $users[i])
                            Spacer()
                        }
                        .background { Color(uiColor: UIColor.systemBackground) }
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .id(i)
                if i != users.count - 1 {
                    Divider()
                        .padding()
                }
            }
            .fullScreenCover(item: $selectedAccount) { account in
                AccountDetailView(userid: account.id, accountModel: account)
            }
        }
    }
    
    private var paginationCursor: some View {
        Color.clear
            .task {
                if let cursor = cloudViewModel.cursorMain, !cloudViewModel.isFetching, spots.count > 0 {
                    let newSpots = await cloudViewModel.fetchMoreSpotsPublic(cursor: cursor, desiredKeys: cloudViewModel.desiredKeys, resultLimit: cloudViewModel.limit)
                    DispatchQueue.main.async {
                        spots += newSpots
                        hasError = false
                    }
                }
            }
    }
    
    private var paginationCursorUsers: some View {
        Color.clear
            .task {
                if let cursor = cloudViewModel.cursorUsers, !isFetchingUsers, !users.isEmpty {
                    let newUsers = await cloudViewModel.fetchMoreAccounts(cursor: cursor)
                    DispatchQueue.main.async {
                        users += newUsers
                        hasError = false
                    }
                }
            }
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
    
    private func listOfUsers(scroll: ScrollViewProxy) -> some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            userRows
            if isFetchingUsers {
                progressSpinner
            } else {
                paginationCursorUsers
            }
        }
        .onChange(of: isSearchingUsers) { _ in
            refreshUsers()
        }
        .animation(.default, value: users)
        .onChange(of: scrollToTopUsers) { _ in
            scrollToTopUsers(scroll: scroll)
        }
    }
    
    private var listSpots: some View {
        VStack(spacing: 0) {
            DiscoverSearchBar(searchText: (showUserSearch == 1 ? $searchTextUsers : $searchText),
                              searching: (showUserSearch == 1 ? $isSearchingUsers : $isSearching),
                              searchName: (showUserSearch == 1 ? $usersSearchText : $searchLocationName),
                              hasSearched: (showUserSearch == 1 ? $hasSearchedUsers : $hasSearched)).padding(.vertical, 10)
            VStack(spacing: 0) {
                switchView
                TabView(selection: $showUserSearch) {
                    spotsSearch
                        .tag(0)
                    userView
                        .onAppear {
                            if (users.isEmpty) {
                                refreshUsers()
                            }
                        }
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .navigationTitle(showUserSearch == 1 ? usersSearchText : "Spots")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if showUserSearch == 0 {
                    chooseDistanceMenu
                    mapButton
                }
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                if showUserSearch == 0 {
                    displayLocationIcon
                }
            }
        }
    }
    
    private var switchView: some View {
        HStack(spacing: 0) {
            Text("Spots")
                .font(.callout)
                .fontWeight(.semibold)
                .scaleEffect(0.9)
                .padding(.vertical,6)
                .foregroundColor(showUserSearch == 0 ? .white : (colorScheme == .dark ? .white : .black))
                .frame(maxWidth: .infinity)
                .background {
                    if showUserSearch == 0 {
                        Capsule()
                            .fill(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Capsule())
                .onTapGesture {
                    showUserSearch = 0
                }
            Text("Users".localized())
                .font(.callout)
                .fontWeight(.semibold)
                .scaleEffect(0.9)
                .padding(.vertical,6)
                .foregroundColor(showUserSearch == 1 ? .white : (colorScheme == .dark ? .white : .black))
                .frame(maxWidth: .infinity)
                .background {
                    if showUserSearch == 1 {
                        Capsule()
                            .fill(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Capsule())
                .onTapGesture {
                    showUserSearch = 1
                }
        }
        .padding(.horizontal)
        .padding(.bottom, 5)
    }
    
    private var spotsSearch: some View {
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
    
    private var userView: some View {
        ScrollViewReader { scroll in
            ScrollView(showsIndicators: false) {
                PullToRefresh(coordinateSpaceName: "pullToRefreshUsers") {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    refreshUsers()
                }
                listOfUsers(scroll: scroll)
            }
        }
        .coordinateSpace(name: "pullToRefreshUsers")
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
        if (spots.isEmpty) {
            refreshSpots()
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
                    hasError = false
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
                hasError = false
            }
        }
    }
    
    private func refreshSpots() {
        loadSpotsFromDB(location: CLLocation(latitude: mapViewModel.searchingHere.center.latitude, longitude: mapViewModel.searchingHere.center.longitude), radiusInMeters: CGFloat(distance), filteringBy: sortBy)
    }
    
    private func refreshUsers() {
        if isFetchingUsers { return }
        isFetchingUsers = true
        if !searchTextUsers.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            hasSearchedUsers = true
        } else {
            hasSearchedUsers = false
        }
        Task {
            let newUsers = await cloudViewModel.fetchAccounts(searchText: searchTextUsers)
            DispatchQueue.main.async {
                users = newUsers
                isFetchingUsers = false
                scrollToTopUsers.toggle()
            }
        }
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
    
    private func scrollToTopUsers(scroll: ScrollViewProxy) {
        if users.count > 0 {
            withAnimation(.easeInOut(duration: 0.5)) {
                scroll.scrollTo(0, anchor: .top)
            }
        }
    }
}
