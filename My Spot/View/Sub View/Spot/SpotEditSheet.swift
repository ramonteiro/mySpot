//
//  SpotEditSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine

struct SpotEditSheet: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var networkViewModel: NetworkMonitor
    @ObservedObject var spot:Spot
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var tags = ""
    @State private var isPublic = false
    @State private var wasPublic = false
    @State private var emoji = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var nameInTitle = ""
    
    
    private enum Field {
        case name
        case descript
        case founder
        case emoji
    }
    
    @FocusState private var focusState: Field?
    
    private var keepDisabled: Bool {
        !((!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !descript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPublic) || (isPublic && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !descript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || !cloudViewModel.isSignedInToiCloud || !networkViewModel.hasInternet)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Spot Name")) {
                    TextField("Enter Spot Name", text: $name)
                        .onReceive(Just(name)) { _ in
                            if (name.count > MaxCharLength.names) {
                                name = String(name.prefix(MaxCharLength.names))
                            }
                        }
                        .onAppear {
                            name = spot.name!
                        }
                        .focused($focusState, equals: .name)
                        .submitLabel(.next)
                }
                Section(header: Text("Founder's Name")) {
                    TextField("Enter Founder's Name", text: $founder)
                        .focused($focusState, equals: .founder)
                        .submitLabel(.next)
                        .textContentType(.givenName)
                        .onAppear {
                            founder = spot.founder!
                        }
                        .onReceive(Just(founder)) { _ in
                            if (founder.count > MaxCharLength.names) {
                                founder = String(founder.prefix(MaxCharLength.names))
                            }
                        }
                }
                if (!wasPublic) {
                    Section(header: Text("Share Spot")) {
                        if (networkViewModel.hasInternet && !isFromDB()) {
                            displayIsPublicPrompt
                        } else if (!networkViewModel.hasInternet) {
                            Text("Internet Is Required To Share Spot.")
                        } else if (isFromDB()) {
                            Text("Saved Spots Cannot Be Reposted.")
                        }
                    }
                } else {
                    Section(header: Text("Emoji")) {
                        EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
                            .onReceive(Just(emoji), perform: { _ in
                                self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                            })
                            .submitLabel(.next)
                            .focused($focusState, equals: .emoji)
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
                    .onAppear {
                        descript = spot.details!
                    }
                    .focused($focusState, equals: .descript)
                    .onReceive(Just(descript)) { _ in
                        if (descript.count > MaxCharLength.description) {
                            descript = String(descript.prefix(MaxCharLength.description))
                        }
                    }
                }
            }
            .onSubmit {
                switch focusState {
                case .name:
                    focusState = .founder
                case .founder:
                    if (wasPublic || isPublic) {
                        focusState = .emoji
                    } else {
                        focusState = .descript
                    }
                case .emoji:
                    focusState = .descript
                default:
                    focusState = nil
                }
            }
            .navigationTitle(name)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if (wasPublic) {
                            isPublic = true
                        }
                        tags = descript.findTags()
                        if (isPublic && wasPublic) {
                            updatePublic()
                            saveChanges()
                        } else if (!wasPublic && isPublic) {
                            savePublic()
                        } else {
                            saveChanges()
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .accentColor(.blue)
                    .disabled(keepDisabled)
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        name = ""
                        founder = ""
                        descript = ""
                        emoji = ""
                        tags = ""
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    HStack {
                        Button {
                            switch focusState {
                            case .descript:
                                if (isPublic || wasPublic) {
                                    focusState = .emoji
                                } else {
                                    focusState = .founder
                                }
                            case .founder:
                                focusState = .name
                            case .emoji:
                                focusState = .founder
                            default:
                                focusState = nil
                            }
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .disabled(focusState == .name)
                        Button {
                            switch focusState {
                            case .name:
                                focusState = .founder
                            case .founder:
                                if (isPublic || wasPublic) {
                                    focusState = .emoji
                                } else {
                                    focusState = .descript
                                }
                            case .emoji:
                                focusState = .descript
                            default:
                                focusState = nil
                            }
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .disabled(focusState == .descript)
                        Spacer()
                        Button("Done") {
                            focusState = nil
                        }
                    }
                }
            }
            .onAppear() {
                wasPublic = spot.isPublic
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
    
    private func saveChanges() {
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        if (isPublic) {
            spot.emoji = emoji
        }
        spot.tags = tags
        try? moc.save()
    }
    
    private func savePublic() {
        let id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: spot.date!, locationName: spot.locationName ?? "", x: spot.x, y: spot.y, description: descript, type: tags, image: spot.image!, emoji: emoji)
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        if (isPublic) {
            spot.emoji = emoji
        }
        spot.tags = tags
        spot.dbid = id
        try? moc.save()
    }
    
    private func updatePublic() {
        cloudViewModel.updateSpotPublic(spot: spot, newName: name, newDescription: descript, newFounder: founder, newType: tags, newEmoji: emoji)
    }
    
    private var displayIsPublicPrompt: some View {
        VStack {
            Toggle("Public", isOn: $isPublic.animation())
            if (isPublic) {
                EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
                    .onReceive(Just(emoji), perform: { _ in
                        self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                    })
                    .submitLabel(.next)
                    .focused($focusState, equals: .emoji)
            }
        }
    }
}
