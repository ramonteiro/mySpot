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
    @State private var locationIcon = "location"
    
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
    
    private func delete(at offsets: IndexSet) {
        offsets.forEach { i in
            DispatchQueue.main.async {
                playlist.spotArr[i].playlist = nil
                try? moc.save()
            }
        }
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
                if (locationIcon == LocationForSorting.locationOn) {
                    listFiltered
                } else {
                    listUnfiltered
                }
            } else {
                displayMessageNoSpotsFound
            }
        }
        .onChange(of: tabController.playlistPopToRoot) { _ in
            presentationMode.wrappedValue.dismiss()
        }
        .onAppear() {
            setFilteringType()
            filter()
        }
        .navigationTitle((playlist.name ?? "") + (playlist.emoji ?? ""))
        .listRowSeparator(.hidden)
        .navigationBarItems(leading: displayLocationIcon.disabled(!mapViewModel.isAuthorized))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    showingMapSheet.toggle()
                }) {
                    Image(systemName: "map").imageScale(.large)
                }
                .disabled(playlist.spotArr.count == 0)
                .sheet(isPresented: $showingMapSheet) {
                    ViewPlaylistMap(playlist: playlist)
                }
                Button(action: {
                    if (locationIcon == LocationForSorting.locationOn) {
                        locationIcon = LocationForSorting.locationOff
                        UserDefaults.standard.set(false, forKey: UserDefaultKeys.isFilterByLocation)
                    }
                    showingAddSpotToPlaylistSheet = true
                }) {
                    Image(systemName: "plus").imageScale(.large)
                }
                .sheet(isPresented: $showingAddSpotToPlaylistSheet) {
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
    }
    
    private var displayLocationIcon: some View {
        Button(action: {
            if (locationIcon == LocationForSorting.locationOn) {
                locationIcon = LocationForSorting.locationOff
                UserDefaults.standard.set(false, forKey: UserDefaultKeys.isFilterByLocation)
            } else {
                mapViewModel.checkLocationAuthorization()
                locationIcon = LocationForSorting.locationOn
                UserDefaults.standard.set(true, forKey: UserDefaultKeys.isFilterByLocation)
                filter()
            }
        }) {
            Image(systemName: locationIcon).imageScale(.large)
        }
        .onChange(of: mapViewModel.isAuthorized) { newValue in
            if (!newValue) {
                locationIcon = LocationForSorting.locationOff
                UserDefaults.standard.set(false, forKey: UserDefaultKeys.isFilterByLocation)
            }
        }
    }
    
    private func setFilteringType() {
        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.isFilterByLocation)) {
            if (UserDefaults.standard.value(forKey: UserDefaultKeys.isFilterByLocation) as! Bool == false) {
                locationIcon = LocationForSorting.locationOff
            } else {
                locationIcon = LocationForSorting.locationOn
            }
        } else {
            locationIcon = LocationForSorting.locationOff
        }
    }
    
    private func filter() {
        if (locationIcon == LocationForSorting.locationOn) {
            filteredSpots = playlist.spotArr.sorted { (spot1, spot2) -> Bool in
                guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
                guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
                let distanceFromSpot1 = distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
                let distanceFromSpot2 = distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
                return distanceFromSpot1 < distanceFromSpot2
            }
        }
    }
    
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
    
    private var listFiltered: some View {
        List {
            ForEach(filteredSpots) { spot in
                NavigationLink(destination: DetailView(fromPlaylist: true, spot: spot)) {
                    SpotRow(spot: spot)
                }
            }
            .onDelete(perform: self.deleteFiltered)
        }
    }
    
    private var listUnfiltered: some View {
        List {
            ForEach(playlist.spotArr) { spot in
                NavigationLink(destination: DetailView(fromPlaylist: true, spot: spot)) {
                    SpotRow(spot: spot)
                }
            }
            .onDelete(perform: self.delete)
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
}
