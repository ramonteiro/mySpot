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
import Network

struct AddSpotSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var showingAlert = false
    @State private var hasInternet = true
    @State private var name = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var type = ""
    @State private var isPublic = false
    @State private var changeProfileImage = false
    @State private var openCameraRoll = false
    @State private var canSubmitPic = false
    @State private var emoji = ""
    @State private var imageSelected = UIImage()
    
    @FocusState private var nameIsFocused: Bool
    @FocusState private var descriptIsFocused: Bool
    @FocusState private var founderIsFocused: Bool
    @FocusState private var emojiIsFocused: Bool
    @FocusState private var typeIsFocused: Bool
    
    let monitor = NWPathMonitor()

    var body: some View {
        ZStack {
            if (mapViewModel.getIsAuthorized()) {
                NavigationView {
                    Form {
                        Section(header: Text("Spot Name")) {
                            displayNamePrompt
                        }
                        Section(header: Text("Founder's Name")) {
                            displayFounderPrompt
                        }
                        Section(header: Text("Spot Tag")) {
                            displaySpotTag
                        }
                        Section(header: Text("Share Spot")) {
                            displayIsPublicPrompt
                                .disabled(!hasInternet || !cloudViewModel.isSignedInToiCloud)
                        }
                        Section(header: Text("Spot Description")) {
                            displayDescriptionPrompt
                        }
                        Section(header: Text("Date Found")) {
                            Text(getDate())
                        }
                        Section(header: Text("Spot Location")) {
                            Text("Latitude: \(getLongitude())")
                            Text("Longitude: \(getLatitude())")
                            NavigationLink(destination: ViewOnlyUserOnMap()) {
                                Text("Show Map")
                            }
                        }
                        Section(header: Text("Photo of Spot")) {
                            displayPhotoButton
                        }
                    }
                    .onAppear {
                        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.founder) && founder == "") {
                            founder = UserDefaults.standard.value(forKey: UserDefaultKeys.founder) as! String
                        }
                    }
                    .accentColor(.red)
                    .sheet(isPresented: $openCameraRoll) {
                        TakePhoto(selectedImage: $imageSelected, sourceType: .camera)
                            .ignoresSafeArea()
                    }
                    .navigationTitle("Create Spot")
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Button("Done") {
                                nameIsFocused = false
                                founderIsFocused = false
                                descriptIsFocused = false
                                typeIsFocused = false
                                emojiIsFocused = false
                            }
                        }
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button("Save") {
                                if (!hasInternet) {
                                    isPublic = false
                                }
                                if (isPublic) {
                                    savePublic()
                                } else {
                                    save()
                                    close()
                                }
                            }
                            .padding()
                            .disabled(name == "" || descript == "" || canSubmitPic == false || founder == "" || isEmojiNeeded() || (isPublic && !cloudViewModel.isSignedInToiCloud))
                        }
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button("Delete") {
                                showingAlert = true
                            }
                            .alert("Are you sure you want to delete spot?", isPresented: $showingAlert) {
                                Button("Yes", role: .destructive) { close() }
                            }
                            .padding()
                            .accentColor(.red)
                        }
                    }
                }
                .onAppear() {
                    checkForInternetConnection()
                }
                .interactiveDismissDisabled()
            } else {
                VStack {
                    Text("Location services are not enabled for mySpot.")
                    Text("Please enable location in settings.")
                    Button("Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                }
                .accentColor(.red)
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
    
    private var displayPhotoButton: some View {
        Button(action: {
            changeProfileImage = true
            openCameraRoll = true
            founderIsFocused = false
            nameIsFocused = false
            descriptIsFocused = false
            emojiIsFocused = false
            typeIsFocused = false
            
                
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
    
    private var displaySpotTag: some View {
        TextField("Enter Tag", text: $type, prompt: Text("ex: Skating").font(.subheadline).foregroundColor(.gray))
            .focused($typeIsFocused)
            .onReceive(Just(type)) { _ in
                if (type.count > MaxCharLength.names) {
                    type = String(founder.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var displayDescriptionPrompt: some View {
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
    
    private var displayFounderPrompt: some View {
        TextField("Enter Founder Name", text: $founder)
            .focused($founderIsFocused)
            .onReceive(Just(founder)) { _ in
                if (founder.count > MaxCharLength.names) {
                    founder = String(founder.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var displayNamePrompt: some View {
        TextField("Enter Spot Name", text: $name)
            .focused($nameIsFocused)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
    }

    private func isEmojiNeeded() -> Bool {
        if isPublic {
            return emoji == ""
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
        newSpot.x = getLatitude()
        newSpot.y = getLongitude()
        newSpot.isPublic = isPublic
        newSpot.date = getDate()
        if (isPublic) {
            newSpot.emoji = emoji
        }
        if (type == "") {
            newSpot.type = "none"
        } else {
            newSpot.type = type
        }
        newSpot.id = UUID()
        try? moc.save()
    }
    
    private func savePublic() {
        let id: String
        if (type == "") {
            id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: getDate(), x: getLatitude(), y: getLongitude(), description: descript, type: "none", image: imageSelected, emoji: emoji)
        } else {
            id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: getDate(), x: getLatitude(), y: getLongitude(), description: descript, type: type, image: imageSelected, emoji: emoji)
        }
        UserDefaults.standard.set(founder, forKey: UserDefaultKeys.founder)
        let newSpot = Spot(context: moc)
        newSpot.founder = founder
        newSpot.details = descript
        newSpot.image = imageSelected
        newSpot.name = name
        newSpot.x = getLatitude()
        newSpot.y = getLongitude()
        newSpot.isPublic = isPublic
        if (isPublic) {
            newSpot.emoji = emoji
        }
        newSpot.date = getDate()
        if (type == "") {
            newSpot.type = "none"
        } else {
            newSpot.type = type
        }
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

// compresses uiimage to send to firebase storage
extension UIImage {
    func aspectFittedToHeight(_ newHeight: CGFloat) -> UIImage {
        let scale = newHeight / self.size.height
        let newWidth = self.size.width * scale
        let newSize = CGSize(width: newWidth, height: newHeight)
        let renderer = UIGraphicsImageRenderer(size: newSize)

        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UserDefaults {

    func valueExists(forKey key: String) -> Bool {
        return object(forKey: key) != nil
    }

}
