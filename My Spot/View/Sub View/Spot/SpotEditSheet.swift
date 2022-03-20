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
    @State private var founder = ""
    @State private var descript = ""
    @State private var nameInTitle = ""
    @State private var fromDB = false
    
    
    private enum Field {
        case name
        case descript
        case founder
    }
    
    @FocusState private var focusState: Field?
    
    private var keepDisabled: Bool {
        (fromDB && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || (!fromDB && (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
    }
    
    var body: some View {
        NavigationView {
            if ((wasPublic && networkViewModel.hasInternet) || (!wasPublic)) {
                Form {
                    Section(header: Text("Spot Name*")) {
                        TextField("Enter Spot Name", text: $name)
                            .onReceive(Just(name)) { _ in
                                if (name.count > MaxCharLength.names) {
                                    name = String(name.prefix(MaxCharLength.names))
                                }
                            }
                            .onAppear {
                                name = spot.name ?? ""
                            }
                            .focused($focusState, equals: .name)
                            .submitLabel(.next)
                    }
                    if !fromDB {
                        Section(header: Text("Founder's Name*")) {
                            TextField("Enter Founder's Name", text: $founder)
                                .focused($focusState, equals: .founder)
                                .submitLabel(.next)
                                .textContentType(.givenName)
                                .onAppear {
                                    founder = spot.founder ?? ""
                                }
                                .onReceive(Just(founder)) { _ in
                                    if (founder.count > MaxCharLength.names) {
                                        founder = String(founder.prefix(MaxCharLength.names))
                                    }
                                }
                        }
                        if (!wasPublic) {
                            Section(header: Text("Share Spot")) {
                                if (networkViewModel.hasInternet) {
                                    displayIsPublicPrompt
                                } else if (!networkViewModel.hasInternet) {
                                    Text("Internet Is Required To Share Spot.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .onAppear {
                                            isPublic = false
                                        }
                                }
                            }
                        }
                    }
                    Section(header: Text("Spot Description")) {
                        ZStack {
                            TextEditor(text: $descript)
                            Text(descript).opacity(0).padding(.all, 8)
                        }
                        .focused($focusState, equals: .descript)
                        .onReceive(Just(descript)) { _ in
                            if (descript.count > MaxCharLength.description) {
                                descript = String(descript.prefix(MaxCharLength.description))
                            }
                        }
                    }
                    .onAppear {
                        descript = spot.details ?? ""
                    }
                }
                .onSubmit {
                    switch focusState {
                    case .name:
                        if (fromDB) {
                            focusState = .descript
                        } else {
                            focusState = .founder
                        }
                    case .founder:
                        focusState = .descript
                    default:
                        focusState = nil
                    }
                }
                .navigationTitle(name)
                .navigationViewStyle(.stack)
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
                        .padding(.trailing)
                        .tint(.blue)
                        .disabled(keepDisabled)
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            name = ""
                            founder = ""
                            descript = ""
                            tags = ""
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.leading)
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        HStack {
                            Button {
                                switch focusState {
                                case .descript:
                                    if (fromDB) {
                                        focusState = .name
                                    } else {
                                        focusState = .founder
                                    }
                                case .founder:
                                    focusState = .name
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
                                    if (fromDB) {
                                        focusState = .descript
                                    } else {
                                        focusState = .founder
                                    }
                                case .founder:
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
            } else {
                VStack {
                    Spacer()
                    Text("Internet Is Required To Update Public Spots.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .onAppear {
            wasPublic = spot.isPublic
            fromDB = isFromDB()
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
        spot.tags = tags
        try? moc.save()
    }
    
    private func savePublic() {
        guard let imageData = spot.image?.pngData() else { return }
        let id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: spot.date ?? "", locationName: spot.locationName ?? "", x: spot.x, y: spot.y, description: descript, type: tags, image: imageData)
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        spot.tags = tags
        spot.dbid = id
        try? moc.save()
    }
    
    private func updatePublic() {
        cloudViewModel.updateSpotPublic(spot: spot, newName: name, newDescription: descript, newFounder: founder, newType: tags)
    }
    
    private var displayIsPublicPrompt: some View {
        Toggle("Public", isOn: $isPublic)
    }
}
