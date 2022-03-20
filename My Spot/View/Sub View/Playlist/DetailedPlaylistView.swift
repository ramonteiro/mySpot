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

struct DetailPlaylistView: View {
    
    @ObservedObject var playlist: Playlist
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabController: TabController
    
    @State private var showingAddSpotToPlaylistSheet = false
    @State private var showingRemoveSpotToPlaylistSheet = false
    @State private var showingEditSheet = false
    @State private var showingMapSheet = false
    @State private var filteredSpots: [Spot] = []
    @State private var searchText = ""
    @State private var sortBy = "Name"
    
    private var searchResults: [Spot] {
            if searchText.isEmpty {
                return filteredSpots
            } else {
                return filteredSpots.filter { $0.name!.lowercased().contains(searchText.lowercased()) || $0.tags!.lowercased().contains(searchText.lowercased()) || $0.founder!.lowercased().contains(searchText.lowercased())}
            }
        }
    
    var body: some View {
        if (playlistExist()) {
            displayDetailedView
        }
    }
    
    private func playlistExist() -> Bool {
        guard let _ = playlist.name else {return false}
        guard let _ = playlist.emoji else {return false}
        return true
    }
    
    private func deleteFiltered(at offsets: IndexSet) {
        offsets.forEach { i in
            playlist.spotArr.forEach { j in
                if (filteredSpots[i] == j) {
                    DispatchQueue.main.async {
                        j.playlist = nil
                        try? moc.save()
                    }
                }
            }
        }
        filteredSpots.remove(atOffsets: offsets)
    }
    
    private var displayDetailedView: some View {
        ZStack {
            if (playlist.spotArr.count > 0) {
                listFiltered
                    .onChange(of: sortBy) { sortType in
                        if (sortType == "Name") {
                            sortName()
                        } else if (sortType == "Newest") {
                            sortDate()
                        } else if (sortType == "Closest") {
                            sortClosest()
                        }
                    }
            } else {
                displayMessageNoSpotsFound
            }
        }
        .navigationTitle((playlist.name ?? "") + (playlist.emoji ?? ""))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack {
                    Button{
                        showingMapSheet.toggle()
                    } label: {
                        Image(systemName: "map").imageScale(.large)
                    }
                    .disabled(playlist.spotArr.count == 0)
                    .fullScreenCover(isPresented: $showingMapSheet) {
                        ViewPlaylistMap(playlist: playlist)
                    }
                    Button{
                        showingAddSpotToPlaylistSheet = true
                    } label: {
                        Image(systemName: "plus").imageScale(.large)
                    }
                    .sheet(isPresented: $showingAddSpotToPlaylistSheet, onDismiss: setFilteringType) {
                        AddSpotToPlaylistSheet(currPlaylist: playlist)
                    }
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .sheet(isPresented: $showingEditSheet) {
                        PlaylistEditSheet(playlist: playlist)
                    }
                }
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                displayLocationIcon
            }
        }
        .onChange(of: tabController.playlistPopToRoot) { _ in
            presentationMode.wrappedValue.dismiss()
        }
        .onAppear() {
            mapViewModel.checkLocationAuthorization()
            setFilteringType()
        }
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortClosest()
            } label: {
                Text("Closest")
            }
            .disabled(!mapViewModel.isAuthorized)
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
    
    private func setFilteringType() {
            if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
                sortBy = UserDefaults.standard.string(forKey: "savedSort") ?? "Name"
                if (sortBy == "Name") {
                    filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                        guard let name1 = spot1.name else { return true }
                        guard let name2 = spot2.name else { return true }
                        if (name1 < name2) {
                            return true
                        } else {
                            return false
                        }
                    }
                } else if (sortBy == "Newest") {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMM d, yyyy"
                    filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
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
                } else if (sortBy == "Closest" && mapViewModel.isAuthorized) {
                    filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                        guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
                        guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
                        let distanceFromSpot1 = distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
                        let distanceFromSpot2 = distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
                        return distanceFromSpot1 < distanceFromSpot2
                    }
                } else if (sortBy == "Closest" && !mapViewModel.isAuthorized) {
                    filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                        guard let name1 = spot1.name else { return true }
                        guard let name2 = spot2.name else { return true }
                        if (name1 < name2) {
                            return true
                        } else {
                            return false
                        }
                    }
                    sortBy = "Name"
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
                sortBy = "Closest"
                UserDefaults.standard.set(sortBy, forKey: "savedSort")
            }
    }
    
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
    
    private var listFiltered: some View {
        ZStack {
            List {
                ForEach(searchResults) { spot in
                    NavigationLink(destination: DetailView(fromPlaylist: true, spot: spot)) {
                        SpotRow(spot: spot)
                    }
                }
                .onDelete(perform: self.deleteFiltered)
            }
            .searchable(text: $searchText, prompt: "Search \(playlist.name ?? "")\(playlist.emoji ?? "")")
        }
    }
    
    private var displayMessageNoSpotsFound: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("No Spots Here Yet!")
                Spacer()
            }
            HStack {
                Spacer()
                Text("Add Some With The Plus Button Above").font(.subheadline).foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private func sortClosest() {
        filteredSpots = filteredSpots.sorted { (spot1, spot2) -> Bool in
            guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
            guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
            let distanceFromSpot1 = distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
            let distanceFromSpot2 = distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
            return distanceFromSpot1 < distanceFromSpot2
        }
        sortBy = "Closest"
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
        sortBy = "Name"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private func sortDate() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        filteredSpots = filteredSpots.sorted { (spot1, spot2) -> Bool in
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
        sortBy = "Newest"
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
}
