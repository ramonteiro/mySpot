//
//  DetailedPlaylistView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DetailPlaylistView:
 navigation link for each playlist item in list in root view
 */

import SwiftUI
import MapKit
import CloudKit
import CoreData

struct DetailPlaylistView: View {
    
    let playlist: Playlist
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var showingAddSpotToPlaylistSheet = false
    @State private var showingRemoveSpotToPlaylistSheet = false
    @State private var showErrorSavingAlert = false
    @State private var showNoPermissionsAlert = false
    @State private var showingDeleteAlert = false
    @State private var showFailedShareAlert = false
    @State private var showingEditSheet = false
    @State private var showingMapSheet = false
    @State private var showShareSheet = false
    @State private var share: CKShare?
    @State private var toBeDeleted: IndexSet?
    @State private var deleteAlertText = ""
    @State private var loadingShare = false
    @State private var shareIcon = "person.crop.circle"
    @State private var filteredSpots: [Spot] = []
    @State private var searchResults: [Spot] = []
    @State private var searchText = ""
    @State private var sortBy = "Name".localized()
    @State private var isSaving = false
    @State private var errorSaving = false
    @State private var didDelete = false
    
    private var canEdit: Bool {
        CoreDataStack.shared.canEdit(object: playlist)
    }
    
    var body: some View {
        playlistView
            .navigationTitle("Spots")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    trailingNavigationButtons
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    HStack(spacing: 0) {
                        shareButton
                        displayLocationIcon
                    }
                }
            }
            .onChange(of: playlist.spotArr.count) { _ in
                setFilteringType()
            }
            .onChange(of: CoreDataStack.shared.isShared(object: playlist)) { isShared in
                if isShared {
                    shareIcon = "person.crop.circle"
                } else {
                    shareIcon = "person.crop.circle.badge.plus"
                }
                setFilteringType()
            }
            .onChange(of: tabController.playlistPopToRoot) { _ in
                presentationMode.wrappedValue.dismiss()
            }
            .onAppear {
                getShare()
                setFilteringType()
            }
            .sheet(isPresented: $showShareSheet) {
                if let share = share {
                    CloudSharingView(share: share, container: CoreDataStack.shared.ckContainer, playlist: playlist)
                }
            }
            .alert("Unable To Share".localized(), isPresented: $showFailedShareAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Please check internet connection and try again.".localized())
            }
            .alert("Unable Add Spots".localized(), isPresented: $showErrorSavingAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Please check internet connection and try again.".localized())
            }
    }
    
    // MARK: - Sub Views
    
    private var shareButton: some View {
        Button {
            if !CoreDataStack.shared.isShared(object: playlist) {
                loadingShare = true
                Task {
                    await createShare(playlist)
                    loadingShare = false
                }
            } else {
                self.share = CoreDataStack.shared.getShare(playlist)
                showShareSheet = true
            }
        } label: {
            if !loadingShare {
                Image(systemName: shareIcon)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
        }
    }
    
    private var mapButton: some View {
        Button {
            showingMapSheet.toggle()
        } label: {
            Image(systemName: "map").imageScale(.large)
        }
        .disabled(playlist.spotArr.count == 0)
        .fullScreenCover(isPresented: $showingMapSheet) {
            MapViewSpots(spots: $filteredSpots, sortBy: $sortBy, searchText: nil)
        }
    }
    
    private var addPlaylistButton: some View {
        Button {
            showingAddSpotToPlaylistSheet = true
        } label: {
            if !isSaving {
                Image(systemName: "plus").imageScale(.large)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(5)
            }
        }
        .disabled(!CoreDataStack.shared.canEdit(object: playlist) || isSaving)
        .sheet(isPresented: $showingAddSpotToPlaylistSheet) {
            AddSpotToPlaylistSheet(currPlaylist: playlist,
                                   currentSpots: getCurrentSpotIds(),
                                   isSaving: $isSaving,
                                   errorSaving: $errorSaving)
        }
    }
    
    private var editButton: some View {
        Button("Edit".localized()) {
            showingEditSheet = true
        }
        .disabled(!CoreDataStack.shared.canEdit(object: playlist))
        .sheet(isPresented: $showingEditSheet) {
            PlaylistEditSheet(playlist: playlist)
        }
    }
    
    private var trailingNavigationButtons: some View {
        HStack {
            mapButton
            addPlaylistButton
            editButton
        }
        .onChange(of: isSaving) { newValue in
            if !newValue {
                setFilteringType()
            }
        }
        .onChange(of: errorSaving) { newValue in
            if errorSaving {
                errorSaving = false
                showErrorSavingAlert = true
            }
        }
    }
    
    @ViewBuilder
    private var playlistView: some View {
        if (filteredSpots.count > 0) {
            listFiltered
                .onChange(of: sortBy) { sortType in
                    if (sortType == "Name".localized()) {
                        sortName()
                    } else if (sortType == "Newest".localized()) {
                        sortDate()
                    } else if (sortType == "Closest".localized()) {
                        sortClosest()
                    }
                    filterSearch()
                }
        } else {
            displayMessageNoSpotsFound
        }
    }
    
    private var displayDetailedView: some View {
        ZStack {
            if (filteredSpots.count > 0) {
                listFiltered
                    .onChange(of: sortBy) { sortType in
                        if (sortType == "Name".localized()) {
                            sortName()
                        } else if (sortType == "Newest".localized()) {
                            sortDate()
                        } else if (sortType == "Closest".localized()) {
                            sortClosest()
                        }
                    }
            } else {
                displayMessageNoSpotsFound
            }
        }
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortClosest()
                filterSearch()
            } label: {
                Text("Sort By Closest".localized())
            }
            .disabled(!mapViewModel.isAuthorized)
            Button {
                sortDate()
                filterSearch()
            } label: {
                Text("Sort By Newest".localized())
            }
            Button {
                sortName()
                filterSearch()
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
    
    private var listFiltered: some View {
        ZStack {
            List {
                ForEach(0..<searchResults.count, id: \.self) { i in
                    HStack {
                        Spacer()
                        NavigationLink {
                            DetailView(isSheet: false, from: Tab.playlists, spot: searchResults[i], didDelete: $didDelete)
                        } label: {
                            MapSpotPreview(spot: $searchResults[i])
                                .alert(isPresented: self.$showingDeleteAlert) {
                                    Alert(title: Text("Are you sure you want to delete?".localized()),
                                          message: Text(deleteAlertText),
                                          primaryButton: .destructive(Text("Delete".localized())) {
                                        self.deleteFiltered(at: self.toBeDeleted!)
                                        self.toBeDeleted = nil
                                    }, secondaryButton: .cancel() {
                                        self.toBeDeleted = nil
                                    }
                                    )
                                }
                        }
                        .scaleEffect(0.9)
                        Spacer()
                    }
                    .listRowBackground(Color(uiColor: UIColor.systemBackground))
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                }
                .onDelete(perform: self.deleteRow)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search ".localized() + (playlist.name ?? "") + (playlist.emoji ?? ""))
            .onChange(of: searchText) { _ in
                filterSearch()
            }
        }
        .alert("Invalid Permission".localized(), isPresented: $showNoPermissionsAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("The owner has not allowed you to removed spots.".localized())
        }
    }
    
    private var displayMessageNoSpotsFound: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("No Spots Here Yet!".localized())
                Spacer()
            }
            HStack {
                Spacer()
                HStack {
                    Text("Add Some With The".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Image(systemName: "plus")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("Button Above".localized())
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
    
    // MARK: - Functions
    
    private func deleteFiltered(at offsets: IndexSet) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        offsets.forEach { i in
            playlist.spotArr.forEach { j in
                if (filteredSpots[i] == j) {
                    if !CoreDataStack.shared.isShared(object: j) {
                        DispatchQueue.main.async {
                            j.playlist = nil
                            CoreDataStack.shared.save()
                            filteredSpots.remove(atOffsets: offsets)
                            return
                        }
                    } else if CoreDataStack.shared.canDelete(object: j) {
                        DispatchQueue.main.async {
                            j.playlist = nil
                            CoreDataStack.shared.deleteSpot(j)
                            filteredSpots.remove(atOffsets: offsets)
                            return
                        }
                    } else {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                        showNoPermissionsAlert = true
                    }
                }
            }
        }
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        self.toBeDeleted = indexSet
        self.showingDeleteAlert = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func getCurrentSpotIds() -> [String] {
        var matchingStrings: [String] = []
        for spot in filteredSpots {
            let string = "\(spot.name ?? "name")\(spot.x + spot.y)"
            matchingStrings.append(string)
        }
        return matchingStrings
    }
    
    private func setFilteringType() {
        if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
            sortBy = (UserDefaults.standard.string(forKey: "savedSort") ?? "Name").localized()
            if (sortBy == "Name".localized()) {
                filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                    guard let name1 = spot1.name else { return true }
                    guard let name2 = spot2.name else { return true }
                    if (name1 < name2) {
                        return true
                    } else {
                        return false
                    }
                }
            } else if (sortBy == "Newest".localized()) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
                filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                    if let date1 = spot1.dateObject, let date2 = spot2.dateObject {
                        if (date1 > date2) {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        guard let dateString1 = spot1.date else { return true }
                        guard let dateString2 = spot2.date else { return true }
                        guard let date1 = dateFormatter.date(from: dateString1) else { return true }
                        guard let date2 = dateFormatter.date(from: dateString2) else { return true }
                        if (date1 > date2) {
                            return true
                        } else {
                            return false
                        }
                    }
                }
            } else if (sortBy == "Closest".localized() && mapViewModel.isAuthorized) {
                filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                    guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
                    guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
                    let distanceFromSpot1 = mapViewModel.distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
                    let distanceFromSpot2 = mapViewModel.distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
                    return distanceFromSpot1 < distanceFromSpot2
                }
            } else if (sortBy == "Closest".localized() && !mapViewModel.isAuthorized) {
                filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                    guard let name1 = spot1.name else { return true }
                    guard let name2 = spot2.name else { return true }
                    if (name1 < name2) {
                        return true
                    } else {
                        return false
                    }
                }
                sortBy = "Name".localized()
                UserDefaults.standard.set(sortBy, forKey: "savedSort")
            }
        } else {
            filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                guard let name1 = spot1.name else { return true }
                guard let name2 = spot2.name else { return true }
                if (name1 < name2) {
                    return true
                } else {
                    return false
                }
            }
            sortBy = "Closest".localized()
            UserDefaults.standard.set(sortBy, forKey: "savedSort")
        }
        
        if let _ = share {
            filteredSpots = filteredSpots.filter { spot in
                spot.isShared
            }
        }
        filterSearch()
    }
    
    private func sortClosest() {
        filteredSpots = filteredSpots.sorted { (spot1, spot2) -> Bool in
            guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
            guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
            let distanceFromSpot1 = mapViewModel.distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
            let distanceFromSpot2 = mapViewModel.distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
            return distanceFromSpot1 < distanceFromSpot2
        }
        sortBy = "Closest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private func sortName() {
        filteredSpots = filteredSpots.sorted { (spot1, spot2) -> Bool in
            guard let name1 = spot1.name else { return true }
            guard let name2 = spot2.name else { return true }
            if (name1 < name2) {
                return true
            } else {
                return false
            }
        }
        sortBy = "Name".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private func sortDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
        filteredSpots = filteredSpots.sorted { (spot1, spot2) -> Bool in
            if let date1 = spot1.dateObject, let date2 = spot2.dateObject {
                if (date1 > date2) {
                    return true
                } else {
                    return false
                }
            } else {
                guard let dateString1 = spot1.date else { return true }
                guard let dateString2 = spot2.date else { return true }
                guard let date1 = dateFormatter.date(from: dateString1) else { return true }
                guard let date2 = dateFormatter.date(from: dateString2) else { return true }
                if (date1 > date2) {
                    return true
                } else {
                    return false
                }
            }
        }
        sortBy = "Newest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private func createShare(_ playlist: Playlist) async {
        do {
            let (_, share, _) = try await CoreDataStack.shared.persistentContainer.share([playlist], to: nil)
            share[CKShare.SystemFieldKey.title] = playlist.name ?? "Shared Playlist"
            share[CKShare.SystemFieldKey.thumbnailImageData] = playlist.emoji?.image()
            var sharedObjects: [NSManagedObject] = []
            if playlist.spotArr.count > 0 {
                for spot in playlist.spotArr {
                    let newSpot = Spot(context: CoreDataStack.shared.context)
                    newSpot.id = UUID()
                    newSpot.isShared = false
                    newSpot.userId = cloudViewModel.userID
                    newSpot.date = spot.date
                    if let identity = share.currentUserParticipant?.userIdentity.nameComponents {
                        newSpot.addedBy = CoreDataStack.shared.checkName(user: identity)
                    }
                    newSpot.dateAdded = Date()
                    newSpot.dateObject = spot.dateObject
                    newSpot.dbid = spot.dbid
                    newSpot.details = spot.details
                    newSpot.founder = spot.founder
                    newSpot.fromDB = true
                    newSpot.image = spot.image
                    newSpot.image2 = spot.image2
                    newSpot.image3 = spot.image3
                    newSpot.isPublic = spot.isPublic
                    newSpot.likes = spot.likes
                    newSpot.locationName = spot.locationName
                    newSpot.tags = spot.tags
                    newSpot.wasThere = spot.wasThere
                    newSpot.x = spot.x
                    newSpot.y = spot.y
                    newSpot.name = spot.name
                    newSpot.founder = spot.founder
                    sharedObjects.append(newSpot)
                    spot.isShared = true
                    spot.userId = cloudViewModel.userID
                    spot.playlist = playlist
                }
            }
            CoreDataStack.shared.save()
            self.share = share
            showShareSheet = true
            loadingShare = false
        } catch {
            print("Failed to create share")
            loadingShare = false
            showFailedShareAlert = true
        }
    }
    
    private func string(for permission: CKShare.ParticipantPermission) -> String {
        switch permission {
        case .unknown:
            return "Unknown"
        case .none:
            return "None"
        case .readOnly:
            return "Read-Only"
        case .readWrite:
            return "Read-Write"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.Permission")
        }
    }
    
    private func string(for role: CKShare.ParticipantRole) -> String {
        switch role {
        case .owner:
            return "Owner"
        case .privateUser:
            return "Private User"
        case .publicUser:
            return "Public User"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.Role")
        }
    }
    
    private func string(for acceptanceStatus: CKShare.ParticipantAcceptanceStatus) -> String {
        switch acceptanceStatus {
        case .accepted:
            return "Accepted"
        case .removed:
            return "Removed"
        case .pending:
            return "Invited"
        case .unknown:
            return "Unknown"
        @unknown default:
            fatalError("A new value added to CKShare.Participant.AcceptanceStatus")
        }
    }
    
    private func getShare() {
        mapViewModel.checkLocationAuthorization()
        self.share = CoreDataStack.shared.getShare(playlist)
        if !CoreDataStack.shared.isShared(object: playlist) {
            shareIcon = "person.crop.circle.badge.plus"
            deleteAlertText = "The spot will be removed from the playlist.".localized() + " The spot will still be saved in My Spots.".localized()
        } else {
            deleteAlertText = "The spot will be removed from the playlist.".localized() + " If you are the owner of the spot, the spot will still be saved in My Spots.".localized()
        }
    }
    
    private func filterSearch() {
        if searchText.isEmpty {
            searchResults = filteredSpots
        } else {
            searchResults = filteredSpots.filter { spot in
                (spot.name ?? "").lowercased().contains(searchText.lowercased()) ||
                (spot.tags ?? "").lowercased().contains(searchText.lowercased()) ||
                (spot.founder ?? "").lowercased().contains(searchText.lowercased()) ||
                (spot.date ?? "").lowercased().contains(searchText.lowercased())
            }
        }
    }
}
