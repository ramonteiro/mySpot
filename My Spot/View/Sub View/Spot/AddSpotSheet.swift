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
    @State private var showingAddImageAlert = false
    @State private var didCancel = false
    
    @State private var name = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var tags = ""
    @State private var locationName = ""
    @State private var isPublic = false
    
    @State private var long = 1.0
    @State private var lat = 1.0
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage?]?
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || images?.isEmpty ?? true || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (isPublic && !cloudViewModel.isSignedInToiCloud)
    }
    
    private enum Field {
        case name
        case descript
        case founder
    }
    
    private enum ImageCount {
        case main
        case second
        case third
    }
    
    private enum ActiveSheet: Identifiable {
        case cameraSheet
        case cameraRollSheet
        case cropperSheet
        var id: Int {
            hashValue
        }
    }
    
    @State private var activeSheet: ActiveSheet?
    @State private var imageCount: ImageCount?
    @FocusState private var focusState: Field?
    
    var body: some View {
        ZStack {
            if (mapViewModel.isAuthorized) {
                if (lat != 1.0 && networkViewModel.hasInternet) {
                    NavigationView {
                        Form {
                            Section {
                                displayNamePrompt
                            } header: {
                                Text("Spot Name*")
                            }
                            Section {
                                displayFounderPrompt
                                    .onAppear {
                                        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.founder) && founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                                            founder = UserDefaults.standard.value(forKey: UserDefaultKeys.founder) as! String
                                        }
                                    }
                            } header: {
                                Text("Founder's Name*")
                            }
                            Section {
                                if (networkViewModel.hasInternet) {
                                    displayIsPublicPrompt
                                } else {
                                    Text("Internet Is Required To Share Spot.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .onAppear {
                                            isPublic = false
                                        }
                                }
                            } header: {
                                Text("Share Spot")
                            } footer: {
                                Text("Public spots are shown in discover tab to other users.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Section {
                                displayDescriptionPrompt
                            } header: {
                                Text("Spot Description")
                            } footer: {
                                Text("Use # to add tags. Example: #hiking #skating")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Section {
                                Text(getDate())
                            } header: {
                                Text("Date Found")
                            }
                            Section {
                                ViewOnlyUserOnMap()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(15)
                            } header: {
                                Text("Spot Location \(locationName)")
                            } footer: {
                                Text("Location is permanent and cannot be changed after creating spot.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Section {
                                if (images?.count ?? 0 > 0) {
                                    List {
                                        ForEach(images ?? [UIImage(systemName: "exclamationmark.triangle")], id: \.self) { images in
                                            if let images = images {
                                                Image(uiImage: images)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: UIScreen.screenWidth / 2)
                                                    .cornerRadius(10)
                                            }
                                        }
                                        .onMove { indexSet, offset in
                                            images!.move(fromOffsets: indexSet, toOffset: offset)
                                        }
                                        .onDelete { indexSet in
                                            images!.remove(atOffsets: indexSet)
                                        }
                                    }
                                }
                            } header: {
                                Text("Photo of Spot")
                            } footer: {
                                Text("Only 1 image is required (up to 3).")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                        .onSubmit {
                            switch focusState {
                            case .name:
                                focusState = .founder
                            case .founder:
                                focusState = .descript
                            default:
                                focusState = nil
                            }
                        }
                        .confirmationDialog("Choose Image From Photos or Camera", isPresented: $showingAddImageAlert) {
                            Button("Camera") {
                                activeSheet = .cameraSheet
                            }
                            Button("Photos") {
                                activeSheet = .cameraRollSheet
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                        .fullScreenCover(item: $activeSheet) { item in
                            switch item {
                            case .cameraSheet:
                                TakePhoto(selectedImage: $imageTemp)
                                    .onDisappear {
                                        if (imageTemp != nil) {
                                            activeSheet = .cropperSheet
                                        } else {
                                            activeSheet = nil
                                        }
                                        didCancel = false
                                    }
                                    .ignoresSafeArea()
                            case .cameraRollSheet:
                                ChoosePhoto(image: $imageTemp, didCancel: $didCancel)
                                    .onDisappear {
                                        if (!didCancel) {
                                            activeSheet = .cropperSheet
                                        } else {
                                            activeSheet = nil
                                        }
                                        didCancel = false
                                    }
                                    .ignoresSafeArea()
                            case .cropperSheet:
                                MantisPhotoCropper(selectedImage: $imageTemp)
                                    .onDisappear {
                                        if let _ = imageTemp {
                                            images?.append(imageTemp)
                                        }
                                        imageTemp = nil
                                    }
                                    .ignoresSafeArea()
                            }
                        }
                        .navigationTitle("Create Spot")
                        .navigationViewStyle(.stack)
                        .toolbar {
                            ToolbarItemGroup(placement: .bottomBar) {
                                HStack {
                                    Spacer()
                                    
                                    Button {
                                        showingAddImageAlert = true
                                        focusState = nil
                                    } label: {
                                        Image(systemName: "plus")
                                    }
                                    .disabled(images?.count ?? 3 > 2)
                                    
                                    
                                    
                                    EditButton()
                                        .disabled(images?.isEmpty ?? true)
                                    
                                    Spacer()
                                }
                            }
                            ToolbarItemGroup(placement: .keyboard) {
                                HStack {
                                    Button {
                                        switch focusState {
                                        case .founder:
                                            focusState = .name
                                        case .descript:
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
                                }
                                .padding()
                            }
                        }
                    }
                    .onAppear {
                        mapViewModel.checkLocationAuthorization()
                        lat = getLatitude()
                        long = getLongitude()
                        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: lat, longitude: long), completionHandler: { location in
                            locationName = location
                        })
                    }
                    .interactiveDismissDisabled()
                } else {
                    VStack {
                        Text("No Internet Connection Found.")
                        Text("Internet Is Required to Find Location.").font(.subheadline).foregroundColor(.gray)
                    }
                }
            } else {
                VStack {
                    Text("Location services are not enabled for mySpot.")
                    Text("Please enable location in settings.")
                    Button("Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .onAppear {
            lat = getLatitude()
            long = getLongitude()
            images = []
        }
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
                Toggle("Public", isOn: $isPublic)
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
        if let imageData = cloudViewModel.compressImage(image: imageTemp ?? defaultImages.errorImage!).pngData() {
            newSpot.image = UIImage(data: imageData)
        } else {
            return
        }
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
        if let imageData = cloudViewModel.compressImage(image: imageTemp ?? defaultImages.errorImage!).pngData() {
            let id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: getDate(), locationName: locationName, x: lat, y: long, description: descript, type: tags, image: imageData)
            UserDefaults.standard.set(founder, forKey: UserDefaultKeys.founder)
            let newSpot = Spot(context: moc)
            newSpot.founder = founder
            newSpot.details = descript
            newSpot.image = UIImage(data: imageData)
            newSpot.name = name
            newSpot.x = lat
            newSpot.y = long
            newSpot.isPublic = true
            newSpot.date = getDate()
            newSpot.tags = tags
            newSpot.locationName = locationName
            newSpot.id = UUID()
            newSpot.dbid = id
            try? moc.save()
            close()
        } else {
            return
        }
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
