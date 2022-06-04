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
import StoreKit
import Combine

struct AddSpotSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    @FetchRequest(sortDescriptors: []) var colors: FetchedResults<CustomColor>
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var showingAlert = false
    @State private var showingAddImageAlert = false
    @State private var usingCustomLocation = false
    @State private var hasSet = false
    @State private var isFromImagesUnedited = false
    @State private var indexFromUnedited = 0
    @Binding var isSaving: Bool
    
    @State private var name = ""
    @State private var founder = ""
    @State private var descript = ""
    @State private var tags = ""
    @State private var locationName = ""
    @State private var isPublic = true
    
    @State private var long = 1.0
    @State private var centerRegion = MKCoordinateRegion()
    @State private var lat = 1.0
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage?]?
    @State private var imagesUnedited: [UIImage?]?
    @Binding var showingCannotSavePublicAlert: Bool
    @State private var showingCannotSavePrivateAlert: Bool = false
    
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || images?.isEmpty ?? true || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (isPublic && !cloudViewModel.isSignedInToiCloud) || (usingCustomLocation && !hasSet)
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
            if (mapViewModel.isAuthorized || usingCustomLocation) {
                if (lat != 1.0 || usingCustomLocation) {
                    NavigationView {
                        Form {
                            Section {
                                displayNamePrompt
                            } header: {
                                Text("Spot Name*".localized())
                            }
                            Section {
                                displayFounderPrompt
                                    .onAppear {
                                        if (!colors.isEmpty && !(colors[0].name?.isEmpty ?? true) && founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                                            founder = colors[0].name ?? ""
                                        }
                                    }
                            } header: {
                                Text("Founder's Name*".localized())
                            }
                            Section {
                                displayIsPublicPrompt
                            } header: {
                                Text("Share Spot".localized())
                            } footer: {
                                Text("Public spots are shown in discover tab to other users.".localized())
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Section {
                                displayDescriptionPrompt
                            } header: {
                                Text("Spot Description".localized())
                            } footer: {
                                Text("Use # to add tags. Example: #hiking #skating".localized())
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            Section {
                                Text(getDate())
                            } header: {
                                Text("Date Found".localized())
                            }
                            Section {
                                ViewOnlyUserOnMap(customLocation: $usingCustomLocation, hasSet: $hasSet, locationName: $locationName, centerRegion: $centerRegion)
                                    .frame(height: UIScreen.screenHeight * 0.6)
                                    .aspectRatio(contentMode: .fill)
                                    .cornerRadius(15)
                            } header: {
                                HStack {
                                    Image(systemName: (usingCustomLocation ? "mappin" : "figure.wave"))
                                    Text("\(locationName)")
                                }
                            } footer: {
                                Text("Location is permanent and cannot be changed after creating spot.".localized())
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            
                            Section {
                                if (images?.count ?? 0 > 0) {
                                    List {
                                        ForEach(images!.indices, id: \.self) { i in
                                            if let image = images?[i] {
                                                HStack {
                                                    Spacer()
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: UIScreen.screenWidth / 2, alignment: .center)
                                                        .cornerRadius(10)
                                                        .onTapGesture {
                                                            guard let imageTmp = imagesUnedited?[i] else { return }
                                                            imageTemp = imageTmp
                                                            if let _ = imageTemp {
                                                                indexFromUnedited = i
                                                                isFromImagesUnedited = true
                                                                activeSheet = .cropperSheet
                                                            }
                                                        }
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .onMove { indexSet, offset in
                                            images!.move(fromOffsets: indexSet, toOffset: offset)
                                            imagesUnedited!.move(fromOffsets: indexSet, toOffset: offset)
                                        }
                                        .onDelete { indexSet in
                                            images!.remove(atOffsets: indexSet)
                                            imagesUnedited!.remove(atOffsets: indexSet)
                                        }
                                    }
                                }
                            } header: {
                                Text("Photo of Spot".localized())
                            } footer: {
                                Text("Only 1 image is required (up to 3).".localized())
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
                        .alert("Unable To Save Spot".localized(), isPresented: $showingCannotSavePrivateAlert) {
                            Button("OK".localized(), role: .cancel) { }
                        } message: {
                            Text("Failed to save spot. Please try again.".localized())
                        }
                        .confirmationDialog("Choose Image From Photos or Camera".localized(), isPresented: $showingAddImageAlert) {
                            Button("Camera".localized()) {
                                activeSheet = .cameraSheet
                            }
                            Button("Photos".localized()) {
                                activeSheet = .cameraRollSheet
                            }
                            Button("Cancel".localized(), role: .cancel) { }
                        }
                        .fullScreenCover(item: $activeSheet) { item in
                            switch item {
                            case .cameraSheet:
                                TakePhoto(selectedImage: $imageTemp)
                                    .onDisappear {
                                        if (imageTemp != nil) {
                                            imagesUnedited?.append(imageTemp)
                                            isFromImagesUnedited = false
                                            activeSheet = .cropperSheet
                                        } else {
                                            activeSheet = nil
                                        }
                                    }
                                    .ignoresSafeArea()
                            case .cameraRollSheet:
                                ChoosePhoto() { image in
                                    imageTemp = image
                                    imagesUnedited?.append(imageTemp)
                                    isFromImagesUnedited = false
                                    activeSheet = .cropperSheet
                                }
                                .ignoresSafeArea()
                            case .cropperSheet:
                                MantisPhotoCropper(selectedImage: $imageTemp)
                                    .onDisappear {
                                        if let _ = imageTemp {
                                            if isFromImagesUnedited {
                                                images?[indexFromUnedited] = imageTemp
                                            } else {
                                                images?.append(imageTemp)
                                            }
                                        } else {
                                            imagesUnedited?.removeLast()
                                        }
                                        imageTemp = nil
                                        isFromImagesUnedited = false
                                    }
                                    .ignoresSafeArea()
                            }
                        }
                        .navigationTitle("Create Spot".localized())
                        .navigationViewStyle(.automatic)
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
                                    Button("Done".localized()) {
                                        focusState = nil
                                    }
                                }
                            }
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button("Save".localized()) {
                                    tags = descript.findTags()
                                    if (isPublic) {
                                        Task {
                                            isSaving = true
                                            await savePublic()
                                            isSaving = false
                                        }
                                        close()
                                    } else {
                                        Task {
                                            isSaving = true
                                            await save()
                                            isSaving = false
                                        }
                                    }
                                }
                                .tint(.blue)
                                .padding()
                                .disabled(disableSave || isSaving)
                            }
                            ToolbarItemGroup(placement: .navigationBarLeading) {
                                Button("Delete".localized()) {
                                    showingAlert = true
                                }
                                .alert("Are you sure you want to delete spot?".localized(), isPresented: $showingAlert) {
                                    Button("Delete".localized(), role: .destructive) { close() }
                                }
                                .padding()
                            }
                        }
                    }
                    .onAppear {
                        mapViewModel.checkLocationAuthorization()
                        lat = getLatitude()
                        long = getLongitude()
                        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), completionHandler: { location in
                            locationName = location
                        })
                    }
                    .interactiveDismissDisabled()
                } else {
                    VStack {
                        Text("No Internet Connection Found.".localized())
                        Text("Internet Is Required to Find Location.".localized()).font(.subheadline).foregroundColor(.gray)
                    }
                }
            } else {
                VStack {
                    Text("Location services are not enabled for My Spot.".localized())
                    Text("Please enable location in settings.".localized())
                    Button("Settings".localized()) {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    .padding(.bottom)
                    Text("Or create a spot with a custom location".localized())
                    Button("Set Custom Location".localized()) {
                        usingCustomLocation = true
                    }
                }
            }
        }
        .onAppear {
            if !cloudViewModel.isSignedInToiCloud {
                isPublic = false
            }
            if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
                isPublic = false
            }
            lat = getLatitude()
            long = getLongitude()
            images = []
            imagesUnedited = []
        }
        .disabled(isSaving)
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
            if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
                Text("You Are Banned".localized())
            } else if (cloudViewModel.isSignedInToiCloud) {
                Toggle("Public".localized(), isOn: $isPublic)
            } else if (!cloudViewModel.isSignedInToiCloud) {
                Text("Sign in to iCloud to Share Spots".localized() + "(" + "Check discover tab for more help".localized() + ")")
            }
        }
    }
    
    private var displayFounderPrompt: some View {
        TextField("Enter Founder Name".localized(), text: $founder)
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
        TextField("Enter Spot Name".localized(), text: $name)
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
        timeFormatter.dateFormat = "MMM d, yyyy; HH:mm:ss"
        let stringDate = timeFormatter.string(from: time)
        return stringDate
    }
    
    private func save() async {
        let newSpot = Spot(context: moc)
        if let imageData = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
            newSpot.image = UIImage(data: imageData)
        } else {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if (images?.count == 3) {
            if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                newSpot.image2 = UIImage(data: imageData)
            } else {
                showingCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
            if let imageData = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                newSpot.image3 = UIImage(data: imageData)
            } else {
                showingCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
        } else if (images?.count == 2) {
            if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                newSpot.image2 = UIImage(data: imageData)
            } else {
                showingCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
        }
        UserDefaults.standard.set(founder, forKey: UserDefaultKeys.founder)
        if (usingCustomLocation) {
            newSpot.x = centerRegion.center.latitude
            newSpot.y = centerRegion.center.longitude
            newSpot.wasThere = false
        } else {
            newSpot.x = lat
            newSpot.y = long
            newSpot.wasThere = true
        }
        
        newSpot.isShared = false
        newSpot.userId = cloudViewModel.userID
        newSpot.founder = founder
        newSpot.details = descript
        newSpot.name = name
        newSpot.fromDB = false
        newSpot.isPublic = false
        newSpot.date = getDate()
        newSpot.tags = tags
        newSpot.locationName = locationName
        newSpot.id = UUID()
        do {
            try CoreDataStack.shared.context.save()
            askForReview()
        } catch {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        close()
    }
    
    private func askForReview() {
        if (!UserDefaults.standard.valueExists(forKey: "askedAlready")) {
            UserDefaults.standard.set(false, forKey: "askedAlready")
        }
        if (UserDefaults.standard.bool(forKey: "askedAlready")) {
            return
        }
        if (UserDefaults.standard.valueExists(forKey: "spotsCount")) {
            UserDefaults.standard.set(UserDefaults.standard.integer(forKey: "spotsCount") + 1, forKey: "spotsCount")
        } else {
            UserDefaults.standard.set(1, forKey: "spotsCount")
        }
        
        if (UserDefaults.standard.integer(forKey: "spotsCount") > 3) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
                UserDefaults.standard.set(true, forKey: "askedAlready")
            }
        }
    }
    
    private func savePublic() async {
        let newSpot = Spot(context: moc)
        if let imageData = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
            newSpot.image = UIImage(data: imageData)
            var imageData2: Data? = nil
            var imageData3: Data? = nil
            if (images?.count == 3) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    newSpot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
                if let imageData3Check = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                    newSpot.image3 = UIImage(data: imageData3Check)
                    imageData3 = imageData3Check
                }
            } else if (images?.count == 2) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    newSpot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
            }
            do {
                let id = try await cloudViewModel.addSpotToPublic(name: name, founder: founder, date: getDate(), locationName: locationName, x: (usingCustomLocation ? centerRegion.center.latitude : lat), y: (usingCustomLocation ? centerRegion.center.longitude : long), description: descript, type: tags, image: imageData, image2: imageData2, image3: imageData3, isMultipleImages: (images?.count ?? 1) - 1, customLocation: usingCustomLocation, dateObject: Date())
                if !id.isEmpty {
                    newSpot.dbid = id
                    newSpot.isPublic = true
                } else {
                    newSpot.dbid = ""
                    newSpot.isPublic = false
                }
            } catch {
                newSpot.dbid = ""
                newSpot.isPublic = false
            }
            if (!colors.isEmpty) {
                colors[0].name = founder
            }
            newSpot.founder = founder
            newSpot.details = descript
            newSpot.name = name
            newSpot.likes = 0
            newSpot.fromDB = false
            if (usingCustomLocation) {
                newSpot.x = centerRegion.center.latitude
                newSpot.y = centerRegion.center.longitude
                newSpot.wasThere = false
            } else {
                newSpot.x = lat
                newSpot.y = long
                newSpot.wasThere = true
            }
            newSpot.date = getDate()
            newSpot.tags = tags
            newSpot.locationName = locationName
            newSpot.id = UUID()
            newSpot.isShared = false
            newSpot.userId = cloudViewModel.userID
            do {
                try CoreDataStack.shared.context.save()
            } catch {
                showingCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
            if newSpot.isPublic {
                askForReview()
            } else {
                showingCannotSavePublicAlert = true
            }
        } else {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
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
