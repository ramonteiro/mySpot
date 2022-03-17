//
//  AddSpotSheet.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 AddSpotSheet:
 Dsiplays prompts to create new spot and sends to db if public
 */

import SwiftUI
import MapKit
import Combine

struct AddSpotSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var networkViewModel: NetworkMonitor
    
    @State private var showingAlert = false
    @State private var name = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var tags = ""
    @State private var locationName = ""
    @State private var isPublic = false
    @State private var changeProfileImage = false
    @State private var openCameraRoll = false
    @State private var canSubmitPic = false
    @State private var emoji = ""
    @State private var long = 1.0
    @State private var lat = 1.0
    @State private var imageSelected = UIImage()
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || descript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || canSubmitPic == false || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isEmojiNeeded() || (isPublic && !cloudViewModel.isSignedInToiCloud)
    }
    
    private enum Field {
        case name
        case descript
        case founder
        case emoji
    }
    
    @FocusState private var focusState: Field?
    
    var body: some View {
        ZStack {
            if (mapViewModel.getIsAuthorized()) {
                if (getLatitude() != 1.0) {
                    NavigationView {
                        Form {
                            Section(header: Text("Spot Name")) {
                                displayNamePrompt
                            }
                            Section(header: Text("Founder's Name")) {
                                displayFounderPrompt
                            }
                            Section(header: Text("Share Spot")) {
                                if (networkViewModel.hasInternet) {
                                    displayIsPublicPrompt
                                } else {
                                    Text("Internet Is Required To Share Spot.")
                                }
                            }
                            Section(header: Text("Spot Description")) {
                                displayDescriptionPrompt
                            }
                            Section(header: Text("Date Found")) {
                                Text(getDate())
                            }
                            Section(header: Text("Spot Location")) {
                                ViewOnlyUserOnMap()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                            }
                            Section(header: Text("Photo of Spot")) {
                                displayPhotoButton
                            }
                        }
                        .onSubmit {
                            switch focusState {
                            case .name:
                                focusState = .founder
                            case .founder:
                                if (isPublic) {
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
                        .onAppear {
                            if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.founder) && founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                                founder = UserDefaults.standard.value(forKey: UserDefaultKeys.founder) as! String
                            }
                        }
                        .sheet(isPresented: $openCameraRoll) {
                            TakePhoto(selectedImage: $imageSelected, sourceType: .camera)
                                .ignoresSafeArea()
                        }
                        .navigationTitle("Create Spot")
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                HStack {
                                    Button {
                                        switch focusState {
                                        case .founder:
                                            focusState = .name
                                        case .emoji:
                                            focusState = .founder
                                        case .descript:
                                            if (isPublic) {
                                                focusState = .emoji
                                            } else {
                                                focusState = .founder
                                            }
                                        default:
                                            focusState = nil
                                        }
                                    } label: {
                                        Image(systemName: "chevron.up")
                                            .tint(.blue)
                                    }
                                    .disabled(focusState == .name)
                                    Button {
                                        switch focusState {
                                        case .name:
                                            focusState = .founder
                                        case .founder:
                                            if (isPublic) {
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
                                            .tint(.blue)
                                    }
                                    .disabled(focusState == .descript)
                                    Spacer()
                                    Button("Done") {
                                        focusState = nil
                                    }
                                    .tint(.blue)
                                }
                            }
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button("Save") {
                                    if (!networkViewModel.hasInternet) {
                                        isPublic = false
                                    }
                                    tags = descript.findTags()
                                    if (isPublic) {
                                        savePublic()
                                    } else {
                                        save()
                                        close()
                                    }
                                }
                                .tint(.blue)
                                .padding()
                                .disabled(disableSave)
                            }
                            ToolbarItemGroup(placement: .navigationBarLeading) {
                                Button("Delete") {
                                    showingAlert = true
                                }
                                .alert("Are you sure you want to delete spot?", isPresented: $showingAlert) {
                                    Button("Delete", role: .destructive) { close() }
                                        .tint(.blue)
                                }
                                .padding()
                            }
                        }
                    }
                    .onAppear {
                        lat = getLatitude()
                        long = getLongitude()
                        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: lat, longitude: long), completionHandler: { location in
                            locationName = location
                        })
                    }
                    .interactiveDismissDisabled()
                } else {
                    Text("No Internet Connection Found.")
                    Text("Internet Is Required to Find Location.").font(.subheadline).foregroundColor(.gray)
                }
            } else {
                VStack {
                    Text("Location services are not enabled for mySpot.")
                    Text("Please enable location in settings.")
                    Button("Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
            }
        }
    }
    
    private var displayPhotoButton: some View {
        Button(action: {
            changeProfileImage = true
            openCameraRoll = true
            focusState = nil
            
            
        }, label: {
            if ((changeProfileImage && imageSelected.cgImage != nil) || (changeProfileImage && imageSelected.ciImage != nil)) {
                Image(uiImage: imageSelected)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
                    .onAppear(perform: {canSubmitPic = true})
            } else {
                Text("Add Photo")
                    .onAppear(perform: {canSubmitPic = false})
            }
        })
    }
    
    private var displayDescriptionPrompt: some View {
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
    
    private var displayIsPublicPrompt: some View {
        VStack {
            if (cloudViewModel.isSignedInToiCloud) {
                Toggle("Public", isOn: $isPublic.animation())
                if (isPublic) {
                    EmojiTextField(text: $emoji, placeholder: "Enter Emoji")
                        .onReceive(Just(emoji), perform: { _ in
                            self.emoji = String(self.emoji.onlyEmoji().prefix(MaxCharLength.emojis))
                        })
                        .submitLabel(.next)
                        .focused($focusState, equals: .emoji)
                }
            } else if (!cloudViewModel.isSignedInToiCloud) {
                Text("You Must Be Signed In To Icloud To Disover And Share Spots")
            }
        }
    }
    
    private var displayFounderPrompt: some View {
        TextField("Enter Founder Name", text: $founder)
            .focused($focusState, equals: .founder)
            .submitLabel(.next)
            .textContentType(.givenName)
            .onReceive(Just(founder)) { _ in
                if (founder.count > MaxCharLength.names) {
                    founder = String(founder.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var displayNamePrompt: some View {
        TextField("Enter Spot Name", text: $name)
            .focused($focusState, equals: .name)
            .submitLabel(.next)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
    }
    
    private func isEmojiNeeded() -> Bool {
        if isPublic {
            return emoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return false
        }
    }
    
    private func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func getDate()->String{
        let time = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MMM d, yyyy"
        let stringDate = timeFormatter.string(from: time)
        return stringDate
    }
    
    private func save() {
        UserDefaults.standard.set(founder, forKey: UserDefaultKeys.founder)
        let newSpot = Spot(context: moc)
        newSpot.founder = founder
        newSpot.details = descript
        newSpot.image = imageSelected
        newSpot.name = name
        newSpot.x = lat
        newSpot.y = long
        newSpot.isPublic = false
        newSpot.date = getDate()
        newSpot.tags = tags
        newSpot.locationName = locationName
        newSpot.id = UUID()
        try? moc.save()
    }
    
    private func savePublic() {
        let id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: getDate(), locationName: locationName, x: lat, y: long, description: descript, type: tags, image: imageSelected, emoji: emoji)
        UserDefaults.standard.set(founder, forKey: UserDefaultKeys.founder)
        let newSpot = Spot(context: moc)
        newSpot.founder = founder
        newSpot.details = descript
        newSpot.image = imageSelected
        newSpot.name = name
        newSpot.x = lat
        newSpot.y = long
        newSpot.isPublic = true
        newSpot.emoji = emoji
        newSpot.date = getDate()
        newSpot.tags = tags
        newSpot.locationName = locationName
        newSpot.id = UUID()
        newSpot.dbid = id
        try? moc.save()
        close()
    }
    
    private func getLongitude() -> Double {
        if let longitude = mapViewModel.locationManager?.location?.coordinate.longitude {
            return longitude
        } else {
            return 1.0
        }
    }
    
    private func getLatitude() -> Double {
        if let latitude = mapViewModel.locationManager?.location?.coordinate.latitude {
            return latitude
        } else {
            return 1.0
        }
    }
}
