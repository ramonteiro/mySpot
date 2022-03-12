//
//  DetailView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DetailView:
 navigation link for each spot from core data item in list in root view
 */

import SwiftUI
import Combine
import MapKit
import Network

struct DetailView: View {
    
    var fromPlaylist: Bool
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @ObservedObject var spot:Spot
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabController: TabController
    
    @State private var showingEditAlert = false
    @State private var hasInternet = true
    @State private var isEditing = false
    @State private var name = ""
    @State private var isPublic = false
    @State private var wasPublic = false
    @State private var emoji = ""
    @State private var type = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var nameInTitle = ""
    
    @FocusState private var nameIsFocused: Bool
    @FocusState private var emojiIsFocused: Bool
    @FocusState private var descriptIsFocused: Bool
    @FocusState private var founderIsFocused: Bool
    @FocusState private var typeIsFocused: Bool
    
    let monitor = NWPathMonitor()
    
    var body: some View {
        if (!isEditing) {
            displaySpot
                .onChange(of: tabController.playlistPopToRoot) { _ in
                    if (fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .onChange(of: tabController.spotPopToRoot) { _ in
                    if (!fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        } else {
            displayEditingMode
                .onChange(of: tabController.playlistPopToRoot) { _ in
                    if (fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .onChange(of: tabController.spotPopToRoot) { _ in
                    if (!fromPlaylist) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .onAppear() {
                    checkForInternetConnection()
                    wasPublic = spot.isPublic
                }
        }
    }
    
    private var displaySpot: some View {
        ZStack {
            if (isExisting()) {
                Form {
                    Image(uiImage: spot.image!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                    Text("Found by: \(spot.founder!)\nOn \(spot.date!)\nTag: \(spot.type!)").font(.subheadline).foregroundColor(.gray)
                    Section(header: Text("Description")) {
                        Text(spot.details!)
                    }
                    Section(header: Text("Location")) {
                        ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name!, coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))])
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                        Button("Take Me To \(spot.name!)") {
                            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                            routeMeTo.name = spot.name!
                            routeMeTo.openInMaps(launchOptions: nil)
                        }
                        .accentColor(.blue)
                    }
                }
                .onAppear() {
                    nameInTitle = spot.name!
                }
                .navigationTitle(nameInTitle)
                .listRowSeparator(.hidden)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            isEditing = true
                        }
                        .disabled(!hasInternet || (!spot.isPublic && isFromDB()) || (spot.isPublic && !cloudViewModel.isSignedInToiCloud))
                        .accentColor(.red)
                    }
                }
            }
        }
    }
    
    private func isFromDB() -> Bool {
        if let _ = spot.dbid {
            return true
        } else {
            return false
        }
    }
    
    private func isExisting() -> Bool {
        if let _ = spot.name {
            return true
        } else {
            return false
        }
    }
    
    private var displayIsPublicPrompt: some View {
        VStack {
            Toggle("Public", isOn: $isPublic)
            if (isPublic) {
                EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
                                .onReceive(Just(emoji), perform: { _ in
                                    self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                                })
                    .focused($emojiIsFocused)
            }
        }
    }
    
    private func checkForInternetConnection() {
        monitor.pathUpdateHandler = { path in
            if path.status != .satisfied {
                hasInternet = false
            }
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    private var displayEditingMode: some View {
        Form {
            Section(header: Text("Spot Name")) {
                TextField("\(spot.name!)", text: $name)
                    .onReceive(Just(name)) { _ in
                        if (name.count > MaxCharLength.names) {
                            name = String(name.prefix(MaxCharLength.names))
                        }
                    }
                    .focused($nameIsFocused)
            }
            Section(header: Text("Founder's Name")) {
                TextField("\(spot.founder!)", text: $founder)
                    .focused($founderIsFocused)
                    .onReceive(Just(founder)) { _ in
                        if (founder.count > MaxCharLength.names) {
                            founder = String(founder.prefix(MaxCharLength.names))
                        }
                    }
            }
            Section(header: Text("Tag")) {
                TextField("\(spot.type!)", text: $type)
                    
                    .focused($typeIsFocused)
                    .onReceive(Just(type)) { _ in
                        if (type.count > MaxCharLength.names) {
                            type = String(founder.prefix(MaxCharLength.names))
                        }
                    }
            }
            if (!wasPublic) {
                Section(header: Text("Share Spot")) {
                    displayIsPublicPrompt
                        .disabled(!hasInternet)
                }
            } else {
                Section(header: Text("Emoji")) {
                    EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
                        .onReceive(Just(emoji), perform: { _ in
                            self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                        })
                        .focused($emojiIsFocused)
                        .onAppear {
                            emoji = spot.emoji!
                        }
                }
            }
            Section(header: Text("Spot Description")) {
                ZStack {
                    TextEditor(text: $descript)
                    Text(descript).opacity(0).padding(.all, 8)
                }
                .focused($descriptIsFocused)
                .onReceive(Just(descript)) { _ in
                    if (descript.count > MaxCharLength.description) {
                        descript = String(descript.prefix(MaxCharLength.description))
                    }
                }
            }
        }
        .navigationTitle(name)
        .onAppear(perform: {
            name = spot.name!
            founder = spot.founder!
            descript = spot.details!
            type = spot.type!
        })
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Done") {
                    showingEditAlert = true
                }
                .alert("Would you like to keep any changes made?", isPresented: $showingEditAlert) {
                    Button("Keep") {
                        if ((name != "" && descript != "" && founder != "" && !isPublic) || (isPublic && name != "" && descript != "" && founder != "" && emoji != "") || !cloudViewModel.isSignedInToiCloud || !hasInternet) {
                            if (wasPublic) {
                                isPublic = true
                            }
                            if (isPublic && wasPublic) {
                                updatePublic()
                                saveChanges()
                            } else if (!wasPublic && isPublic) {
                                savePublic()
                            } else {
                                saveChanges()
                            }
                            isEditing = false
                        }
                        if (name == "") {
                            name = "NAME IS REQUIRED"
                        }
                        if (founder == "") {
                            founder = "FOUNDER IS REQUIRED"
                        }
                        if (descript == "") {
                            descript = "DESCRIPT IS REQUIRED"
                        }
                        if (isPublic && emoji == "") {
                            emoji = "🚫"
                        }
                    }
                    Button("Discard", role: .destructive) {
                        isEditing = false
                        name = ""
                        founder = ""
                        descript = ""
                        emoji = ""
                        type = ""
                    }
                }
                .accentColor(.red)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Button("Done") {
                    nameIsFocused = false
                    descriptIsFocused = false
                    founderIsFocused = false
                    emojiIsFocused = false
                    typeIsFocused = false
                }
            }
        }
    }
    
    private func updatePublic() {
        if (type == "") {
            cloudViewModel.updateSpotPublic(spot: spot, newName: name, newDescription: descript, newFounder: founder, newType: "none", newEmoji: emoji)
        } else {
            cloudViewModel.updateSpotPublic(spot: spot, newName: name, newDescription: descript, newFounder: founder, newType: type, newEmoji: emoji)
        }
    }
    
    private func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func isEmojiNeeded() -> Bool {
        if isPublic {
            return emoji == ""
        } else {
            return false
        }
    }
    
    private func saveChanges() {
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        if (isPublic) {
            spot.emoji = emoji
        }
        if (type == "") {
            spot.type = "none"
        } else {
            spot.type = type
        }
        try? moc.save()
    }
    
    private func savePublic() {
        let id: String
        if (type == "") {
            id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: spot.date!, x: spot.x, y: spot.y, description: descript, type: "none", image: spot.image!, emoji: emoji)
        } else {
            id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: spot.date!, x: spot.x, y: spot.y, description: descript, type: type, image: spot.image!, emoji: emoji)
        }
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        if (isPublic) {
            spot.emoji = emoji
        }
        if (type == "") {
            spot.type = "none"
        } else {
            spot.type = type
        }
        spot.dbid = id
        try? moc.save()
    }
}
