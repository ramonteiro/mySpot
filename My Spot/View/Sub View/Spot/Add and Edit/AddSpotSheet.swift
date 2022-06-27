import SwiftUI
import MapKit
import StoreKit
import Combine
import Vision
import CoreML

enum SavingSpot {
    case didSave
    case errorSavingPublic
    case errorSavingPrivate
    case noChange
}

struct AddSpotSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var presentDeleteAlert = false
    @State private var presentAddImageAlert = false
    @State private var presentMapView = false
    @State private var usingCustomLocation = false
    @State private var isFromImagesUnedited = false
    @State private var indexFromUnedited = 0
    @State private var name = ""
    @State private var descript = ""
    @State private var tags = ""
    @State private var locationName = ""
    @State private var isPublic = true
    @State private var presentCalendar = false
    @State private var dateFound = Date()
    @State private var didSave = false
    @State private var initChecked = false
    @State private var centerRegion = MKCoordinateRegion()
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage?] = []
    @State private var imagesUnedited: [UIImage?] = []
    @State private var activeSheet: ActiveSheet?
    @State private var imageCount: ImageCount?
    @FocusState private var focusState: Field?
    @Binding var isSaving: Bool
    @Binding var progress: SavingSpot
    
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        images.isEmpty ||
        (isPublic && !cloudViewModel.isSignedInToiCloud)
    }
    
    private enum Field {
        case name
        case descript
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
    
    @ViewBuilder
    var body: some View {
        if (mapViewModel.isAuthorized || usingCustomLocation) {
            addSpotView
                .allowsHitTesting(!isSaving)
        } else {
            noLocationWarning
        }
    }
    
    // MARK: - Sub Views
    
    private var noLocationWarning: some View {
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
                withAnimation {
                    usingCustomLocation = true
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            displayDescriptionPrompt
        } header: {
            Text("Spot Description".localized())
        } footer: {
            Text("Use # to add tags. Example: #hiking #skating".localized())
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    private var nameAndPublicSection: some View {
        Section {
            displayNamePrompt
            displayIsPublicPrompt
        } header: {
            Text("Spot Name*".localized())
        } footer: {
            Text("Public spots are shown in discover tab to other users.".localized())
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func imageRowView(index i: Int) -> some View {
        if let image = images[i] {
            HStack {
                Spacer()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: UIScreen.screenWidth / 2, alignment: .center)
                    .cornerRadius(10)
                    .onTapGesture {
                        guard let imageTmp = imagesUnedited[i] else { return }
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
    
    private var imageList: some View {
        List {
            ForEach(images.indices, id: \.self) { i in
                imageRowView(index: i)
                    .listRowBackground(Color(uiColor: UIColor.secondarySystemBackground))
                    .listRowSeparator(.hidden)
            }
            .onMove { indexSet, offset in
                images.move(fromOffsets: indexSet, toOffset: offset)
                imagesUnedited.move(fromOffsets: indexSet, toOffset: offset)
            }
            .onDelete { indexSet in
                images.remove(atOffsets: indexSet)
                imagesUnedited.remove(atOffsets: indexSet)
            }
        }
    }
    
    private var imageSection: some View {
        Section {
            if (images.count > 0) {
                imageList
            }
        } header: {
            Text("Photo of Spot".localized())
        } footer: {
            imageSectionFooter
        }
    }
    
    private var imageSectionFooter: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Only 1 image is required (up to 3).".localized())
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
            HStack {
                Text("Add Some With The".localized())
                    .font(.footnote)
                    .foregroundColor(.gray)
                Image(systemName: "plus")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private var customNavigationBarTitle: some View {
        HStack {
            Spacer()
            VStack {
                HStack {
                    Image(systemName: (usingCustomLocation ? "mappin" : "figure.wave"))
                    Text(locationName.isEmpty ? "My Spot" : locationName)
                }
                .font(.subheadline)
                Text(dateFound.toString())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
    
    private var bottomButtonOverlay: some View {
        HStack {
            Spacer()
            addImageButton
            Spacer()
            EditButton()
                .disabled(images.isEmpty)
            Spacer()
            mapButton
            Spacer()
            calendarButton
            Spacer()
        }
    }
    
    private var addImageButton: some View {
        Button {
            presentAddImageAlert = true
            focusState = nil
        } label: {
            Image(systemName: "plus")
        }
        .disabled(images.count > 2)
    }
    
    private var mapButton: some View {
        Button {
            presentMapView.toggle()
        } label: {
            Image(systemName: "map")
        }
    }
    
    private var calendarButton: some View {
        Button {
            presentCalendar.toggle()
        } label: {
            Image(systemName: "calendar")
        }
    }
    
    private var upButton: some View {
        Button {
            moveUp()
        } label: {
            Image(systemName: "chevron.up")
        }
        .disabled(focusState == .name)
    }
    
    private var downButton: some View {
        Button {
            moveDown()
        } label: {
            Image(systemName: "chevron.down")
        }
        .disabled(focusState == .descript)
    }
    
    private var keyboardButtons: some View {
        HStack {
            upButton
            downButton
            Spacer()
            Button("Done".localized()) {
                focusState = nil
            }
        }
    }
    
    private var addSpotForm: some View {
        Form {
            nameAndPublicSection
            descriptionSection
            imageSection
        }
        .onSubmit {
            moveDown()
        }
        .navigationBarTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(.stack)
        .toolbar {
            ToolbarItemGroup(placement: .principal) {
                customNavigationBarTitle
            }
            ToolbarItemGroup(placement: .bottomBar) {
                bottomButtonOverlay
            }
            ToolbarItemGroup(placement: .keyboard) {
                keyboardButtons
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                saveButton
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                deleteButton
            }
        }
    }
    
    private var deleteButton: some View {
        Button("Delete".localized()) {
            presentDeleteAlert = true
        }
        .padding()
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            saveButtonTapped()
        }
        .tint(.blue)
        .padding()
        .disabled(disableSave || isSaving)

    }
    
    private var addSpotView: some View {
        NavigationView {
            addSpotForm
        }
        .onAppear {
            if !initChecked {
                updateLocationName()
                setIsPublic()
                initChecked = true
            }
        }
        .alert("Are you sure you want to delete spot?".localized(), isPresented: $presentDeleteAlert) {
            Button("Delete".localized(), role: .destructive) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .confirmationDialog("Choose Image From Photos or Camera".localized(), isPresented: $presentAddImageAlert) {
            Button("Camera".localized()) {
                activeSheet = .cameraSheet
            }
            Button("Photos".localized()) {
                activeSheet = .cameraRollSheet
            }
            Button("Cancel".localized(), role: .cancel) { }
        }
        .sheet(isPresented: $presentCalendar) {
            DatePickerSheet(dateFound: $dateFound)
        }
        .fullScreenCover(isPresented: $presentMapView) {
            dismissMap()
        } content: {
            AddSpotMap(customLocation: $usingCustomLocation, didSave: $didSave, centerRegion: $centerRegion)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $activeSheet) { item in
            switchPhotoSheet(sheet: item)
        }
        .interactiveDismissDisabled()
    }
    
    private var takePhotoView: some View {
        TakePhoto(selectedImage: $imageTemp)
            .onDisappear {
                if (imageTemp != nil) {
                    imagesUnedited.append(imageTemp)
                    isFromImagesUnedited = false
                    activeSheet = .cropperSheet
                } else {
                    activeSheet = nil
                }
            }
            .ignoresSafeArea()
    }
    
    private var choosePhotoView: some View {
        ChoosePhoto() { image in
            imageTemp = image
            imagesUnedited.append(imageTemp)
            isFromImagesUnedited = false
            activeSheet = .cropperSheet
        }
        .ignoresSafeArea()
    }
    
    private var photoCropperView: some View {
        MantisPhotoCropper(selectedImage: $imageTemp)
            .onDisappear {
                if let _ = imageTemp {
                    if isFromImagesUnedited {
                        images[indexFromUnedited] = imageTemp
                    } else {
                        images.append(imageTemp)
                    }
                } else {
                    imagesUnedited.removeLast()
                }
                imageTemp = nil
                isFromImagesUnedited = false
            }
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func switchPhotoSheet(sheet: ActiveSheet) -> some View {
        switch sheet {
        case .cameraSheet:
            takePhotoView
        case .cameraRollSheet:
            choosePhotoView
        case .cropperSheet:
            photoCropperView
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
            if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
                Text("You Are Banned".localized())
            } else if (cloudViewModel.isSignedInToiCloud) {
                Toggle("Public".localized(), isOn: $isPublic)
            } else if (!cloudViewModel.isSignedInToiCloud) {
                Text("Sign in to iCloud to Share Spots".localized() + "(" + "Check discover tab for more help".localized() + ")")
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
    
    // MARK: - Functions
    
    private func save() async {
        var hiddenTags = ""
        let newSpot = Spot(context: CoreDataStack.shared.context)
        if let imageData = images[0]?.jpegData(compressionQuality: ImageCompression.value) {
            if let image = UIImage(data: imageData) {
                newSpot.image = image
                hiddenTags += await getTagsFromImage(uiImage: image)
            }
        } else {
            progress = .errorSavingPrivate
            return
        }
        if (images.count == 3) {
            if let imageData = images[1]?.jpegData(compressionQuality: ImageCompression.value) {
                if let image = UIImage(data: imageData) {
                    newSpot.image2 = image
                    hiddenTags += await getTagsFromImage(uiImage: image)
                }
            } else {
                progress = .errorSavingPrivate
                return
            }
            if let imageData = images[2]?.jpegData(compressionQuality: ImageCompression.value) {
                if let image = UIImage(data: imageData) {
                    newSpot.image3 = image
                    hiddenTags += await getTagsFromImage(uiImage: image)
                }
            } else {
                progress = .errorSavingPrivate
                return
            }
        } else if (images.count == 2) {
            if let imageData = images[1]?.jpegData(compressionQuality: ImageCompression.value) {
                if let image = UIImage(data: imageData) {
                    newSpot.image2 = image
                    hiddenTags += await getTagsFromImage(uiImage: image)
                }
            } else {
                progress = .errorSavingPrivate
                return
            }
        }
        if (usingCustomLocation) {
            newSpot.x = centerRegion.center.latitude
            newSpot.y = centerRegion.center.longitude
            newSpot.wasThere = false
        } else {
            newSpot.x = mapViewModel.region.center.latitude
            newSpot.y = mapViewModel.region.center.longitude
            newSpot.wasThere = true
        }
        newSpot.isShared = false
        newSpot.userId = cloudViewModel.userID
        if let founder = UserDefaults.standard.string(forKey: "founder") {
            newSpot.founder = founder
        } else {
            newSpot.founder = "?"
        }
        newSpot.details = descript
        newSpot.name = name
        newSpot.fromDB = false
        newSpot.isPublic = false
        newSpot.date = hiddenTags
        newSpot.dateObject = dateFound
        newSpot.tags = tags
        newSpot.locationName = locationName
        newSpot.id = UUID()
        do {
            try CoreDataStack.shared.context.save()
            progress = .didSave
            askForReview()
        } catch {
            progress = .errorSavingPrivate
            return
        }
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
        var hiddenTags = ""
        let newSpot = Spot(context: CoreDataStack.shared.context)
        if let imageData = images[0]?.jpegData(compressionQuality: ImageCompression.value) {
            if let image = UIImage(data: imageData) {
                newSpot.image = image
                hiddenTags += await getTagsFromImage(uiImage: image)
            }
            var imageData2: Data? = nil
            var imageData3: Data? = nil
            if (images.count == 3) {
                if let imageData2Check = images[1]?.jpegData(compressionQuality: ImageCompression.value) {
                    if let image = UIImage(data: imageData2Check) {
                        newSpot.image2 = image
                        hiddenTags += await getTagsFromImage(uiImage: image)
                    }
                    imageData2 = imageData2Check
                }
                if let imageData3Check = images[2]?.jpegData(compressionQuality: ImageCompression.value) {
                    if let image = UIImage(data: imageData3Check) {
                        newSpot.image3 = image
                        hiddenTags += await getTagsFromImage(uiImage: image)
                    }
                    imageData3 = imageData3Check
                }
            } else if (images.count == 2) {
                if let imageData2Check = images[1]?.jpegData(compressionQuality: ImageCompression.value) {
                    if let image = UIImage(data: imageData2Check) {
                        newSpot.image2 = image
                        hiddenTags += await getTagsFromImage(uiImage: image)
                    }
                    imageData2 = imageData2Check
                }
            }
            do {
                var founder = "?"
                if let founderName = UserDefaults.standard.string(forKey: "founder") {
                    founder = founderName
                }
                let id = try await cloudViewModel.addSpotToPublic(name: name,
                                                                  founder: founder,
                                                                  date: hiddenTags,
                                                                  locationName: locationName,
                                                                  x: (usingCustomLocation ? centerRegion.center.latitude : mapViewModel.region.center.latitude),
                                                                  y: (usingCustomLocation ? centerRegion.center.longitude : mapViewModel.region.center.longitude),
                                                                  description: descript,
                                                                  type: tags,
                                                                  image: imageData,
                                                                  image2: imageData2,
                                                                  image3: imageData3,
                                                                  isMultipleImages: images.count - 1,
                                                                  customLocation: usingCustomLocation,
                                                                  dateObject: dateFound)
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
            if let founderName = UserDefaults.standard.string(forKey: "founder") {
                newSpot.founder = founderName
            } else {
                newSpot.founder = "?"
            }
            newSpot.details = descript
            newSpot.name = name
            newSpot.dateObject = dateFound
            newSpot.likes = 0
            newSpot.fromDB = false
            if (usingCustomLocation) {
                newSpot.x = centerRegion.center.latitude
                newSpot.y = centerRegion.center.longitude
                newSpot.wasThere = false
            } else {
                newSpot.x = mapViewModel.region.center.latitude
                newSpot.y = mapViewModel.region.center.longitude
                newSpot.wasThere = true
            }
            newSpot.date = hiddenTags
            newSpot.tags = tags
            newSpot.locationName = locationName
            newSpot.id = UUID()
            newSpot.isShared = false
            newSpot.userId = cloudViewModel.userID
            do {
                try CoreDataStack.shared.context.save()
            } catch {
                progress = .errorSavingPrivate
                return
            }
            if newSpot.isPublic {
                progress = .didSave
                askForReview()
            } else {
                progress = .errorSavingPublic
            }
        } else {
            progress = .errorSavingPrivate
            return
        }
    }
    
    private func setIsPublic() {
        if !cloudViewModel.isSignedInToiCloud {
            isPublic = false
        }
        if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
            isPublic = false
        }
    }
    
    private func updateLocationName() {
        mapViewModel.checkLocationAuthorization()
        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.region.center.latitude,
                                                                longitude: mapViewModel.region.center.longitude),
                                           isPrecise: true) { location in
            locationName = location
        }
    }
    
    private func dismissMap() {
        if didSave && usingCustomLocation {
            mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: centerRegion.center.latitude,
                                                                    longitude: centerRegion.center.longitude),
                                               isPrecise: true) { name in
                locationName = name
            }
        }
        didSave = false
    }
    
    private func moveDown() {
        switch focusState {
        case .name:
            focusState = .descript
        default:
            focusState = nil
        }
    }
    
    private func moveUp() {
        switch focusState {
        case .descript:
            focusState = .name
        default:
            focusState = nil
        }
    }
    
    private func saveButtonTapped() {
        isSaving = true
        presentationMode.wrappedValue.dismiss()
        Task {
            tags = descript.findTags()
            if (isPublic) {
                await savePublic()
            } else {
                await save()
            }
            isSaving = false
        }
    }
    
    private func getTagsFromImage(uiImage: UIImage) async -> String {
        var returnArray: [String] = []
        guard let cgImage = uiImage.cgImage else { return "" }
        let keep = 10
        do {
            let config = MLModelConfiguration()
            config.computeUnits = MLComputeUnits.all
            config.allowLowPrecisionAccumulationOnGPU = true
            let model1 = try VNCoreMLModel(for: YOLOv3Int8LUT(configuration: config).model)
            let model2 = try VNCoreMLModel(for: MobileNetV2Int8LUT(configuration: config).model)
            let handler = VNImageRequestHandler(cgImage: cgImage)
            let request1 = VNCoreMLRequest(model: model1) { request, error in
                guard let result = request.results as? [VNClassificationObservation] else { return }
                let sortedResult = result.sorted(by: { $0.confidence > $1.confidence })
                var keeps = keep
                for item in sortedResult {
                    if keeps <= 0 { break }
                    print("\(item.confidence), \(item.identifier)")
                    returnArray.append(item.identifier)
                    keeps -= 1
                }
            }
            let request2 = VNCoreMLRequest(model: model2) { request, error in
                guard let result = request.results as? [VNClassificationObservation] else { return }
                let sortedResult = result.sorted(by: { $0.confidence > $1.confidence })
                var keeps = keep
                for item in sortedResult {
                    if keeps <= 0 { break }
                    print("\(item.confidence), \(item.identifier)")
                    returnArray.append(item.identifier)
                    keeps -= 1
                }
            }
            await performRequests([request1, request2], handler: handler)
        } catch {
            return returnArray.joined(separator: ", ")
        }
        return returnArray.joined(separator: ", ")
    }
    
    private func performRequests(_ requests: [VNCoreMLRequest], handler: VNImageRequestHandler) async {
        try? handler.perform(requests)
    }
}
