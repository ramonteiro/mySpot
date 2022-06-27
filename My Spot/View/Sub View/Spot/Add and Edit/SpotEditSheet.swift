//
//  SpotEditSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine
import CloudKit
import AlertToast

struct SpotEditSheet: View {
    
    let spot: Spot
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusState: Field?
    @State private var activeSheet: ActiveSheet?
    @State private var imageCount: ImageCount?
    @State private var nameChecked = false
    @State private var initChecked = false
    @State private var isPublicChecked = false
    @State private var name = ""
    @State private var tags = ""
    @State private var isPublic = false
    @State private var wasPublic = false
    @State private var isSaving = false
    @State private var isFromImagesUnedited = false
    @State private var indexFromUnedited = 0
    @State private var descript = ""
    @State private var nameInTitle = ""
    @State private var imageChanged = false
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage] = []
    @State private var imagesUnedited: [UIImage?] = []
    @State private var presentCannotSaveAlert = false
    @State private var presentAddImageAlert = false
    @State private var presentCannotDeleteAlert = false
    @State private var presentCannotSavePrivateAlert = false
    @Binding var showingCannotSavePublicAlert: Bool
    @Binding var didSave: Bool
    
    
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
    
    private var keepDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        images.isEmpty
    }
    
    var body: some View {
        editSpotView
            .onAppear {
                initializeImages()
            }
            .allowsHitTesting(!isSaving)
            .toast(isPresenting: $isSaving) {
                AlertToast(displayMode: .alert, type: .loading, title: "Saving".localized())
            }
    }
    
    // MARK: - Sub Views
    
    private var editSpotView: some View {
        NavigationView {
            form
                .onSubmit {
                    moveDown()
                }
                .alert("Unable To Save Spot".localized(), isPresented: $presentCannotSavePrivateAlert) {
                    Button("OK".localized(), role: .cancel) { }
                } message: {
                    Text("Failed to save spot. Please try again.".localized())
                }
                .alert("Unable To Remove Public Spot".localized(), isPresented: $presentCannotDeleteAlert) {
                    Button("OK".localized(), role: .cancel) { }
                } message: {
                    Text("Failed to remove spot from discover tab. Please check connection and try again.".localized())
                }
                .alert("Unable To Save Public Spot".localized(), isPresented: $presentCannotSavePrivateAlert) {
                    Button("OK".localized(), role: .cancel) { }
                } message: {
                    Text("Failed to save public spot. Please check connection and try again.".localized())
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
                .fullScreenCover(item: $activeSheet) { item in
                    openPhotoSheet(sheet: item)
                }
                .navigationTitle("")
                .navigationViewStyle(.stack)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .principal) {
                        customNavigationBarTitle
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        imageToolItems
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        saveButtonView
                    }
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        cancelButton
                    }
                    ToolbarItemGroup(placement: .keyboard) {
                        keyBoardButtons
                    }
                }
        }
        .interactiveDismissDisabled()
        .allowsHitTesting(!isSaving)
    }
    
    private var cancelButton: some View {
        Button("Cancel".localized()) {
            name = ""
            descript = ""
            tags = ""
            presentationMode.wrappedValue.dismiss()
        }
        .padding(.leading)
    }
    
    private var customNavigationBarTitle: some View {
        HStack {
            Spacer()
            VStack {
                HStack {
                    Image(systemName: (!spot.wasThere ? "mappin" : "figure.wave"))
                    Text(spot.locationName ?? "My Spot")
                }
                .font(.subheadline)
                Text(spot.dateObject?.toString() ?? spot.date?.components(separatedBy: ";")[0] ?? "")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
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
                        images[indexFromUnedited] = imageTemp ?? defaultImages.errorImage!
                    } else {
                        images.append(imageTemp ?? defaultImages.errorImage!)
                    }
                    imageChanged = true
                } else {
                    imagesUnedited.removeLast()
                }
                imageTemp = nil
                isFromImagesUnedited = false
            }
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private func openPhotoSheet(sheet: ActiveSheet) -> some View {
        switch sheet {
        case .cameraSheet:
            takePhotoView
        case .cameraRollSheet:
            choosePhotoView
        case .cropperSheet:
            photoCropperView
        }
    }
    
    private var saveButtonView: some View {
        Button("Save".localized()) {
            saveButtonTapped()
        }
        .padding(.trailing)
        .tint(.blue)
        .disabled(keepDisabled)
    }
    
    private var nameTextField: some View {
        TextField("Enter Spot Name".localized(), text: $name)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.names) {
                    name = String(name.prefix(MaxCharLength.names))
                }
            }
            .onAppear {
                if !nameChecked {
                    name = spot.name ?? ""
                    nameChecked = true
                }
            }
            .focused($focusState, equals: .name)
            .submitLabel(.next)
    }
    
    private var nameAndPublicSection: some View {
        Section {
            nameTextField
            if !spot.fromDB {
                displayIsPublicPrompt
            }
        } header: {
            Text("Spot Name*".localized())
        } footer: {
            nameAndPublicFooter
        }
    }
    
    @ViewBuilder
    private var nameAndPublicFooter: some View {
        if wasPublic {
            Text("Setting a public spot to private will remove it from discover tab.".localized())
                .font(.footnote)
                .foregroundColor(.gray)
        } else {
            Text("Public spots are shown in discover tab to other users.".localized())
                .font(.footnote)
                .foregroundColor(.gray)
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
        .onAppear {
            if !isPublicChecked {
                isPublic = wasPublic
                isPublicChecked = true
            }
        }
    }
    
    private var textField: some View {
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
    
    private var descriptionSection: some View {
        Section {
            textField
        } header: {
            Text("Spot Description".localized())
        } footer: {
            Text("Use # to add tags. Example: #hiking #skating".localized())
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func imageRowView(index i: Int) -> some View {
        if i < images.count {
            HStack {
                Spacer()
                Image(uiImage: images[i])
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
            }
            .onMove { indexSet, offset in
                images.move(fromOffsets: indexSet, toOffset: offset)
                imagesUnedited.move(fromOffsets: indexSet, toOffset: offset)
                imageChanged = true
            }
            .onDelete { indexSet in
                images.remove(atOffsets: indexSet)
                imagesUnedited.remove(atOffsets: indexSet)
                imageChanged = true
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
    
    private var form: some View {
        Form {
            nameAndPublicSection
            descriptionSection
            imageSection
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
    
    private var keyBoardButtons: some View {
        HStack {
            upButton
            downButton
            Spacer()
            Button("Done".localized()) {
                focusState = nil
            }
        }
    }
    
    private var imageToolItems: some View {
        HStack {
            Spacer()
            Button {
                presentAddImageAlert = true
                focusState = nil
            } label: {
                Image(systemName: "plus")
            }
            .disabled(images.count > 2)
            Spacer()
            EditButton()
                .disabled(images.isEmpty)
            Spacer()
        }
    }
    
    // MARK: - Functions
    
    private func saveChanges() async {
        if (imageChanged) {
            if let imageData = ImageCompression().compress(image: images[0]) {
                spot.image = UIImage(data: imageData)
            }
            if images.count == 2 {
                if let imageData = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData)
                }
                spot.image3 = nil
            } else if images.count == 3 {
                if let imageData = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData)
                }
                if let imageData = ImageCompression().compress(image: images[2]) {
                    spot.image3 = UIImage(data: imageData)
                }
            }
            if images.count == 1 {
                spot.image2 = nil
                spot.image3 = nil
            }
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.details = descript
        if !spot.fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.isPublic = isPublic
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            didSave = true
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            presentCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
    }
    
    private func savePublic() async {
        if let imageData = ImageCompression().compress(image: images[0]) {
            spot.image = UIImage(data: imageData)
            var imageData2: Data? = nil
            var imageData3: Data? = nil
            if (images.count == 3) {
                if let imageData2Check = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
                if let imageData3Check = ImageCompression().compress(image: images[2]) {
                    spot.image3 = UIImage(data: imageData3Check)
                    imageData3 = imageData3Check
                }
            } else if (images.count == 2) {
                if let imageData2Check = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
            }
            do {
                let id = try await cloudViewModel.addSpotToPublic(name: name, founder: UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?", date: spot.date ?? "", locationName: spot.locationName ?? "", x: spot.x, y: spot.y, description: descript, type: tags, image: imageData, image2: imageData2, image3: imageData3, isMultipleImages: images.count - 1, customLocation: !spot.wasThere, dateObject: spot.dateObject)
                if !id.isEmpty {
                    spot.dbid = id
                    spot.isPublic = true
                } else {
                    spot.dbid = ""
                    spot.isPublic = false
                }
                didSave = true
            } catch {
                spot.dbid = ""
                spot.isPublic = false
            }
        } else {
            presentCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if images.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images.count == 2 {
            spot.image3 = nil
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.likes = 0
        spot.details = descript
        if !spot.fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            presentCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if !spot.isPublic {
            showingCannotSavePublicAlert = true
        }
    }
    
    private func removePublic() async {
        do {
            try await cloudViewModel.deleteSpot(id: spot.dbid ?? "")
            spot.isPublic = false
            if (imageChanged) {
                if let imageData = ImageCompression().compress(image: images[0]) {
                    spot.image = UIImage(data: imageData)
                }
                if images.count == 2 {
                    if let imageData = ImageCompression().compress(image: images[1]) {
                        spot.image2 = UIImage(data: imageData)
                    }
                    spot.image3 = nil
                } else if images.count == 3 {
                    if let imageData = ImageCompression().compress(image: images[1]) {
                        spot.image2 = UIImage(data: imageData)
                    }
                    if let imageData = ImageCompression().compress(image: images[2]) {
                        spot.image3 = UIImage(data: imageData)
                    }
                }
                if images.count == 1 {
                    spot.image2 = nil
                    spot.image3 = nil
                }
            }
            let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
            spot.name = name
            spot.details = descript
            if !spot.fromDB {
                spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
            }
            spot.tags = tags
            do {
                try CoreDataStack.shared.context.save()
                didSave = true
                await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
            } catch {
                presentCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
        } catch {
            spot.isPublic = true
            isPublic = true
            presentCannotDeleteAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
    }
    
    private func updatePublic() async {
        var imageData: Data? = nil
        var imageData2: Data? = nil
        var imageData3: Data? = nil
        if let imageDataCheck = ImageCompression().compress(image: images[0]) {
            spot.image = UIImage(data: imageDataCheck)
            imageData = imageDataCheck
            if (images.count == 3) {
                if let imageData2Check = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
                if let imageData3Check = ImageCompression().compress(image: images[2]) {
                    spot.image3 = UIImage(data: imageData3Check)
                    imageData3 = imageData3Check
                }
            } else if (images.count == 2) {
                if let imageData2Check = ImageCompression().compress(image: images[1]) {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
            }
            let id = spot.dbid ?? ""
            do {
                let isSuccess = try await cloudViewModel.updateSpotPublic(id: id, newName: name, newDescription: descript, newFounder: UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?", newType: tags, imageChanged: imageChanged, image: imageData, image2: imageData2, image3: imageData3, isMultipleImages: images.count - 1)
                if isSuccess {
                    spot.isPublic = true
                    didSave = true
                } else {
                    presentCannotSaveAlert = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    return
                }
            } catch {
                presentCannotSaveAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
        } else {
            presentCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if images.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images.count == 2 {
            spot.image3 = nil
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.details = descript
        if !spot.fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            presentCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
    }
    
    private func updateAppGroup(hashcode: String, image: UIImage?, x: Double, y: Double, name: String, locatioName: String) async {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        guard var xArr: [Double] = userDefaults?.object(forKey: "spotXs") as? [Double] else { return }
        guard var yArr: [Double] = userDefaults?.object(forKey: "spotYs") as? [Double] else { return }
        guard var nameArr: [String] = userDefaults?.object(forKey: "spotNames") as? [String] else { return }
        guard var locationNameArr: [String] = userDefaults?.object(forKey: "spotLocationName") as? [String] else { return }
        guard var imgArr: [Data] = userDefaults?.object(forKey: "spotImgs") as? [Data] else { return }
        var index = -1
        
        for i in imgArr.indices {
            let tmp: String = nameArr[i] + "\(xArr[i])\(yArr[i])"
            if tmp == hashcode {
                index = i
                break
            }
        }
        
        if index == -1 { return }
        guard let data = image?.jpegData(compressionQuality: 0.5) else { return }
        let encoded = try! PropertyListEncoder().encode(data)
        locationNameArr[index] = locatioName
        nameArr[index] = name
        xArr[index] = x
        yArr[index] = y
        imgArr[index] = encoded
        userDefaults?.set(locationNameArr, forKey: "spotLocationName")
        userDefaults?.set(xArr, forKey: "spotXs")
        userDefaults?.set(yArr, forKey: "spotYs")
        userDefaults?.set(nameArr, forKey: "spotNames")
        userDefaults?.set(imgArr, forKey: "spotImgs")
        userDefaults?.set(imgArr.count, forKey: "spotCount")
    }
    
    private func initializeImages() {
        if !initChecked {
            if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
                isPublic = false
            }
            wasPublic = spot.isPublic
            images = []
            if let _ = spot.image3 {
                images.append(spot.image ?? defaultImages.errorImage!)
                images.append(spot.image2 ?? defaultImages.errorImage!)
                images.append(spot.image3 ?? defaultImages.errorImage!)
            } else if let _ = spot.image2 {
                images.append(spot.image ?? defaultImages.errorImage!)
                images.append(spot.image2 ?? defaultImages.errorImage!)
            } else if let _ = spot.image {
                images.append(spot.image ?? defaultImages.errorImage!)
            }
            imagesUnedited = images
            initChecked = true
        }
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
        Task {
            presentationMode.wrappedValue.dismiss()
            tags = descript.findTags()
            if (isPublic && wasPublic) {
                await updatePublic()
            } else if (!wasPublic && isPublic) {
                await savePublic()
            } else if (wasPublic && !isPublic) {
                await removePublic()
            } else {
                await saveChanges()
            }
            isSaving = false
        }
    }
}
