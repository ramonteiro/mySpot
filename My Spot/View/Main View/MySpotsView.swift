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
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var presentMapSheet = false
    @State private var presentDeleteAlert = false
    @State private var toBeDeleted: IndexSet?
    @State private var filteredSpots: [Spot] = []
    @State private var searchResults: [Spot] = []
    @State private var searchText = ""
    @State private var sortBy = "Name".localized()
    @State private var didDelete = false
    
    var body: some View {
        NavigationView {
            listFiltered
                .onChange(of: sortBy) { sortType in
                    changeSortType(sortType: sortType)
                }
        }
        .navigationViewStyle(.automatic)
        .onAppear {
            mapViewModel.checkLocationAuthorization()
            setFilteringType()
        }
        .onChange(of: spots.count) { _ in
            setFilteringType()
        }
        .fullScreenCover(isPresented: $presentMapSheet) {
            MapViewSpots(spots: $filteredSpots, sortBy: $sortBy, searchText: nil)
        }
    }
    
    // MARK: - Sub Views
    
    private var listFiltered: some View {
        ZStack {
            List {
                listOfFilteredSpots
            }
            .animation(.default, value: searchResults)
            .searchable(text: $searchText, prompt: "Search All Spots".localized())
            .onChange(of: searchText) { _ in
                filterSearch()
            }
            if filteredSpots.isEmpty {
                noSpotsMessage
            }
        }
        .navigationTitle("My Spots")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
        .disabled(filteredSpots.isEmpty)
    }
    
    private var noSpotsMessage: some View {
        VStack(spacing: 6) {
            noSpotsMessageTitle
            noSpotsMessageSubtitle
        }
    }
    
    private var noSpotsMessageTitle: some View {
        HStack {
            Spacer()
            Text("No Spots Here Yet!".localized())
            Spacer()
        }
    }
    
    private var noSpotsMessageSubtitle: some View {
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
    
    private var listOfFilteredSpots: some View {
        ForEach(0..<searchResults.count, id: \.self) { i in
            NavigationLink {
                DetailView(isSheet: false, from: Tab.spots, spot: searchResults[i], didDelete: $didDelete)
            } label: {
                SpotRow(spot: $searchResults[i])
                    .alert(isPresented: self.$presentDeleteAlert) {
                        deleteSpotAlert
                    }
            }
        }
        .onDelete(perform: deleteRow)
    }
    
    private var displayLocationIcon: some View {
        Menu {
            Button {
                sortClosest(sort: filteredSpots)
            } label: {
                Text("Sort By Closest".localized())
            }
            .disabled(!mapViewModel.isAuthorized)
            Button {
                sortDate(sort: filteredSpots)
            } label: {
                Text("Sort By Newest".localized())
            }
            Button {
                sortName(sort: filteredSpots)
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
    
    private var deleteSpotAlert: Alert {
        Alert(title: Text("Are you sure you want to delete?".localized()), message: Text(""), primaryButton: .destructive(Text("Delete".localized())) {
            self.deleteFiltered(at: self.toBeDeleted!)
            self.toBeDeleted = nil
        }, secondaryButton: .cancel() {
            self.toBeDeleted = nil
        }
        )
    }
    
    // MARK: - Functions
    
    private func sortClosest(sort: [Spot]) {
        filteredSpots = sort.sorted { (spot1, spot2) -> Bool in
            guard let UserY = mapViewModel.locationManager?.location?.coordinate.longitude else { return true }
            guard let UserX = mapViewModel.locationManager?.location?.coordinate.latitude else { return true }
            let distanceFromSpot1 = mapViewModel.distanceBetween(x1: UserX, x2: spot1.x, y1: UserY, y2: spot1.y)
            let distanceFromSpot2 = mapViewModel.distanceBetween(x1: UserX, x2: spot2.x, y1: UserY, y2: spot2.y)
            return distanceFromSpot1 < distanceFromSpot2
        }
        sortBy = "Closest".localized()
        UserDefaults.standard.set(sortBy, forKey: "savedSort")
    }
    
    private func sortName(sort: [Spot]) {
        filteredSpots = sort.sorted { (spot1, spot2) -> Bool in
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
    
    private func sortDate(sort: [Spot]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
        filteredSpots = sort.sorted { (spot1, spot2) -> Bool in
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
    
    private func setFilteringType() {
        if (UserDefaults.standard.valueExists(forKey: "savedSort")) {
            sortBy = (UserDefaults.standard.string(forKey: "savedSort") ?? "Name").localized()
            if sortBy == "Likes".localized() {
                sortDate(sort: spots.reversed())
            } else if (sortBy == "Name".localized()) {
                sortName(sort: spots.reversed())
            } else if (sortBy == "Newest".localized()) {
                sortDate(sort: spots.reversed())
            } else if (sortBy == "Closest".localized() && mapViewModel.isAuthorized) {
                sortClosest(sort: spots.reversed())
            } else if (sortBy == "Closest".localized() && !mapViewModel.isAuthorized) {
                sortName(sort: spots.reversed())
            }
        } else {
            sortName(sort: spots.reversed())
        }
        filterOutSharedSpotsFromPlaylists()
        filterSearch()
        Task {
            await updateAppGroup()
        }
    }
    
    private func filterOutSharedSpotsFromPlaylists() {
        filteredSpots = filteredSpots.filter { spot in
            !spot.isShared
        }
    }
    
    private func deleteRow(at indexSet: IndexSet) {
        self.toBeDeleted = indexSet
        self.presentDeleteAlert = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    private func deleteFiltered(at offsets: IndexSet) {
        offsets.forEach { i in
            spots.forEach { j in
                if (filteredSpots[i] == j) {
                    DispatchQueue.main.async {
                        CoreDataStack.shared.deleteSpot(j)
                        return
                    }
                }
            }
        }
        filteredSpots.remove(atOffsets: offsets)
    }
    
    private func updateAppGroup() async {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        var spotCount = 0
        if let sc = userDefaults?.integer(forKey: "spotCount") {
            spotCount = sc
        }
        
        if spotCount != filteredSpots.count {
            var xArr: [Double] = []
            var yArr: [Double] = []
            var nameArr: [String] = []
            var imgArr: [Data] = []
            var locationNameArr: [String] = []
            filteredSpots.forEach { spot in
                guard let data = spot.image?.jpegData(compressionQuality: 0.5) else { return }
                let encoded = try! PropertyListEncoder().encode(data)
                imgArr.append(encoded)
                xArr.append(spot.x)
                yArr.append(spot.y)
                locationNameArr.append(spot.locationName ?? "")
                nameArr.append(spot.name ?? "Spot")
            }
            userDefaults?.set(locationNameArr, forKey: "spotLocationName")
            userDefaults?.set(xArr, forKey: "spotXs")
            userDefaults?.set(yArr, forKey: "spotYs")
            userDefaults?.set(nameArr, forKey: "spotNames")
            userDefaults?.set(imgArr, forKey: "spotImgs")
            userDefaults?.set(imgArr.count, forKey: "spotCount")
        }
    }
    
    private func changeSortType(sortType: String) {
        if (sortType == "Name".localized()) {
            sortName(sort: filteredSpots)
        } else if (sortType == "Newest".localized()) {
            sortDate(sort: filteredSpots)
        } else if (sortType == "Closest".localized()) {
            sortClosest(sort: filteredSpots)
        }
        filterSearch()
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
