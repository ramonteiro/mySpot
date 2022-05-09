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
import WidgetKit

struct MySpotsView: View {
    
    @FetchRequest(sortDescriptors: [], animation: .default) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var showingAddSheet = false
    @State private var showingMapSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSettings = false
    @State private var badgeNum = 0
    @State private var toBeDeleted: IndexSet?
    @State private var filteredSpots: [Spot] = []
    @State private var searchText = ""
    @State private var showNotificationSheet = false
    @State private var sortBy = "Name".localized()
    @State private var showingCannotSavePublicAlert = false
    @State private var pu = false
    @State private var isSaving = false
    
    private var searchResults: [Spot] {
            if searchText.isEmpty {
                return filteredSpots
            } else {
                return filteredSpots.filter { ($0.name ?? "").lowercased().contains(searchText.lowercased()) || ($0.tags ?? "").lowercased().contains(searchText.lowercased()) || ($0.founder ?? "").lowercased().contains(searchText.lowercased())}
            }
        }
    
    var body: some View {
        NavigationView {
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
                .alert("Unable To Upload Spot".localized(), isPresented: $pu) {
                    Button("OK".localized(), role: .cancel) { }
                } message: {
                    Text("Please check internet connection and try again.".localized())
                }
        }
        .navigationViewStyle(.automatic)
        .onAppear {
            mapViewModel.checkLocationAuthorization()
            setFilteringType()
        }
        .onChange(of: spots.count) { newValue in
            if (newValue > 0 && filteredSpots.count == 0) {
                mapViewModel.checkLocationAuthorization()
                setFilteringType()
            } else if filteredSpots.count > newValue {
                filteredSpots.forEach { spot in
                    if !spots.contains(spot) {
                        if let i = filteredSpots.firstIndex(of: spot) {
                            filteredSpots.remove(at: i)
                        }
                    }
                }
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
        sortBy = "Newest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private var listFiltered: some View {
        ZStack {
            List {
                ForEach(searchResults) { spot in
                    NavigationLink(destination: DetailView(canShare: true, fromPlaylist: false, spot: spot)) {
                        SpotRow(spot: spot)
                            .alert(isPresented: self.$showingDeleteAlert) {
                                Alert(title: Text("Are you sure you want to delete?".localized()), message: Text(""), primaryButton: .destructive(Text("Delete".localized())) {
                                    self.deleteFiltered(at: self.toBeDeleted!)
                                    self.toBeDeleted = nil
                                }, secondaryButton: .cancel() {
                                    self.toBeDeleted = nil
                                }
                                )
                            }
                    }
                }
                .onDelete(perform: deleteRow)
            }
            .animation(.default, value: searchResults)
            .searchable(text: $searchText, prompt: "Search All Spots".localized())
            if (spots.count == 0) {
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
        }
        .navigationTitle("My Spots")
        .onAppear {
            if UserDefaults.standard.valueExists(forKey: "badge") {
                badgeNum = UserDefaults.standard.integer(forKey: "badge")
            } else {
                UserDefaults.standard.set(0, forKey: "badge")
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    Button{
                        showingMapSheet.toggle()
                    } label: {
                        Image(systemName: "map").imageScale(.large)
                    }
                    .fullScreenCover(isPresented: $showingMapSheet) {
                        ViewMapSpots()
                    }
                    .disabled(spots.isEmpty)
                    if !isSaving {
                        Button {
                            UserDefaults.standard.set(Double(-1.0), forKey: "tempPinX")
                            Task { try? await cloudViewModel.isBanned() }
                            showingAddSheet.toggle()
                        } label: {
                            Image(systemName: "plus").imageScale(.large)
                        }
                        .sheet(isPresented: $showingAddSheet, onDismiss: {
                            setFilteringType()
                            if showingCannotSavePublicAlert {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                                pu.toggle()
                                showingCannotSavePublicAlert = false
                            }
                        }) {
                            AddSpotSheet(isSaving: $isSaving, showingCannotSavePublicAlert: $showingCannotSavePublicAlert)
                        }
                    } else {
                        ProgressView().progressViewStyle(.circular).padding()
                    }
                }
            }
             
            ToolbarItemGroup(placement: .navigationBarLeading) {
                HStack(spacing: 0) {
                    Button {
                        showNotificationSheet.toggle()
                    } label: {
                        Image(systemName: "bell")
                    }
                    .if(badgeNum > 0) { view in
                        view.overlay {
                            Badge(count: $badgeNum, color: .red)
                        }
                    }
                    displayLocationIcon
                }
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNotificationSheet) {
            NotificationView()
        }
    }
                
    private func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
    
    private func setFilteringType() {
        if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
            sortBy = (UserDefaults.standard.string(forKey: "savedSort") ?? "Name").localized()
            if sortBy == "Likes".localized() {
                sortBy = "Newest".localized()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
                filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
            } else if (sortBy == "Name".localized()) {
                filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
                filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
            } else if (sortBy == "Closest".localized() && mapViewModel.isAuthorized) {
                filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
                    guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
                    guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
                    let distanceFromSpot1 = distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
                    let distanceFromSpot2 = distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
                    return distanceFromSpot1 < distanceFromSpot2
                }
            } else if (sortBy == "Closest".localized() && !mapViewModel.isAuthorized) {
                filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
            filteredSpots = spots.sorted { (spot1, spot2) -> Bool in
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
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortClosest()
            } label: {
                Text("Sort By Closest".localized())
            }
            .disabled(!mapViewModel.isAuthorized)
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
    
    private func deleteRow(at indexSet: IndexSet) {
        self.toBeDeleted = indexSet
        self.showingDeleteAlert = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func deleteFiltered(at offsets: IndexSet) {
        offsets.forEach { i in
            spots.forEach { j in
                if (filteredSpots[i] == j) {
                    DispatchQueue.main.async {
                        moc.delete(j)
                        try? moc.save()
                        return
                    }
                }
            }
        }
        filteredSpots.remove(atOffsets: offsets)
    }
}
