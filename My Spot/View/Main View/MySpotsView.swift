//
//  MySpotsView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 MySpotsView:
 root of tabbar for MySpots, shows all spots from core data
 */

import SwiftUI
import MapKit
import CoreData

struct MySpotsView: View {
    
    @FetchRequest(sortDescriptors: [
        NSSortDescriptor( keyPath: \Spot.name, ascending: true)
    ], animation: .default) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var showingAddSheet = false
    @State private var showingMapSheet = false
    @State private var locationIcon = "location"
    @State private var filteredSpots: [Spot] = []
    @State private var searchText = ""
    
    var searchResults: [Spot] {
            if searchText.isEmpty {
                return filteredSpots
            } else {
                return filteredSpots.filter { $0.name!.contains(searchText) }
            }
        }
    
    var body: some View {
        NavigationView {
            if (locationIcon == LocationForSorting.locationOn) { //sorted by location
                listFiltered
            } else { // unsorted
                listUnfiltered
            }
        }
        .onAppear {
            setFilteringType()
            filter()
        }
    }
    
    private var listUnfiltered: some View {
        ZStack {
            List {
                ForEach(spots) { spot in
                    NavigationLink(destination: DetailView(fromPlaylist: false, spot: spot)) {
                        SpotRow(spot: spot)
                    }
                }
                .onDelete(perform: self.delete)
            }
            if (spots.count == 0) {
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
                    HStack {
                        Spacer()
                        (Text("Tip: Press ") + Text(Image(systemName: "location")) + Text(" to filter by your location."))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("My Spots")
        .navigationBarItems(trailing:
        HStack {
            Button(action: {
                showingMapSheet.toggle()
            }) {
                Image(systemName: "map").imageScale(.large)
            }
            .disabled(spots.isEmpty)
            .sheet(isPresented: $showingMapSheet) {
                ViewMapSpots()
            }
            Button(action: {
                if (locationIcon == LocationForSorting.locationOn) {
                    locationIcon = LocationForSorting.locationOff
                    UserDefaults.standard.set(false, forKey: UserDefaultKeys.isFilterByLocation)
                }
            showingAddSheet.toggle()
            }) {
                Image(systemName: "plus").imageScale(.large)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSpotSheet()
            }
        }
        )
        .navigationBarItems(leading: displayLocationIcon.disabled(!mapViewModel.isAuthorized))
    }
    
    private var listFiltered: some View {
        ZStack {
            List {
                ForEach(searchResults) { spot in
                    NavigationLink(destination: DetailView(fromPlaylist: false, spot: spot)) {
                        SpotRow(spot: spot)
                    }
                }
                .onDelete(perform: self.deleteFiltered)
            }
            .searchable(text: $searchText)
            if (spots.count == 0) {
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
                    HStack {
                        Spacer()
                        (Text("Tip: Press ") + Text(Image(systemName: "location")) + Text(" to filter by your location."))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("My Spots")
        .navigationBarItems(trailing:
        HStack {
            Button(action: {
                showingMapSheet.toggle()
            }) {
                Image(systemName: "map").imageScale(.large)
            }
            .sheet(isPresented: $showingMapSheet) {
                ViewMapSpots()
            }
            .disabled(spots.isEmpty)
            Button(action: {
                if (locationIcon == LocationForSorting.locationOn) {
                    locationIcon = LocationForSorting.locationOff
                    UserDefaults.standard.set(false, forKey: UserDefaultKeys.isFilterByLocation)
                }
            showingAddSheet.toggle()
            }) {
                Image(systemName: "plus").imageScale(.large)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSpotSheet()
            }
        })
        .navigationBarItems(leading: displayLocationIcon.disabled(!mapViewModel.isAuthorized))
    }
    
    private func filter() {
        if (locationIcon == LocationForSorting.locationOn) {
            filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
    
    private func deleteFiltered(at offsets: IndexSet) {
        offsets.forEach { i in
            spots.forEach { j in
                if (filteredSpots[i] == j) {
                    DispatchQueue.main.async {
                        moc.delete(j)
                        try? moc.save()
                    }
                }
            }
        }
        filteredSpots.remove(atOffsets: offsets)
    }
    
    private func delete(at offsets: IndexSet) {
        offsets.forEach { i in
            DispatchQueue.main.async {
                moc.delete(spots[i])
                try? moc.save()
            }
        }
    }
}
