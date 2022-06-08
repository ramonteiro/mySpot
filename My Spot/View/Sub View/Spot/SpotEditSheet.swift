//
//  SpotEditSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine
import CloudKit

struct SpotEditSheet: View {
    
    @State private var nameChecked = false
    @State private var isPublicChecked = false
    @State private var initChecked = false
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @ObservedObject var spot:Spot
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var tags = ""
    @State private var isPublic = false
    @State private var wasPublic = false
    @State private var isSaving = false
    @State private var isFromImagesUnedited = false
    @State private var indexFromUnedited = 0
    @State private var descript = ""
    @State private var nameInTitle = ""
    @State private var fromDB = false
    @State private var imageChanged = false
    @State private var showingCannotSaveAlert = false
    @State private var showingAddImageAlert = false
    @State private var showingCannotDeleteAlert = false
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage]?
    @State private var imagesUnedited: [UIImage?]?
    @Binding var showingCannotSavePublicAlert: Bool
    @State private var showingCannotSavePrivateAlert: Bool = false
    @Binding var didChange: Bool
    
    
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
    
    @State private var activeSheet: ActiveSheet?
    @State private var imageCount: ImageCount?
    @FocusState private var focusState: Field?
    
    private var keepDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || images?.isEmpty ?? true
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                form
                    .onSubmit {
                        switch focusState {
                        case .name:
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
                    .alert("Unable To Remove Public Spot".localized(), isPresented: $showingCannotDeleteAlert) {
                        Button("OK".localized(), role: .cancel) { }
                    } message: {
                        Text("Failed to remove spot from discover tab. Please check connection and try again.".localized())
                    }
                    .alert("Unable To Save Public Spot".localized(), isPresented: $showingCannotSavePrivateAlert) {
                        Button("OK".localized(), role: .cancel) { }
                    } message: {
                        Text("Failed to save public spot. Please check connection and try again.".localized())
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
                                            images?[indexFromUnedited] = imageTemp ?? defaultImages.errorImage!
                                        } else {
                                            images?.append(imageTemp ?? defaultImages.errorImage!)
                                        }
                                        imageChanged = true
                                    } else {
                                        imagesUnedited?.removeLast()
                                    }
                                    imageTemp = nil
                                    isFromImagesUnedited = false
                                }
                                .ignoresSafeArea()
                        }
                    }
                    .navigationTitle(name)
                    .navigationViewStyle(.automatic)
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            imageToolItems
                        }
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            saveButtonView
                        }
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button("Cancel".localized()) {
                                name = ""
                                descript = ""
                                tags = ""
                                presentationMode.wrappedValue.dismiss()
                            }
                            .padding(.leading)
                        }
                        ToolbarItemGroup(placement: .keyboard) {
                            keyBoardButtons
                        }
                    }
            }
            .interactiveDismissDisabled()
            .allowsHitTesting(!isSaving)
            if isSaving {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView("Saving".localized())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(UIColor.systemBackground))
                    )
            }
        }
        .onAppear {
            if !initChecked {
                if (UserDefaults.standard.valueExists(forKey: "isBanned") && UserDefaults.standard.bool(forKey: "isBanned")) {
                    isPublic = false
                }
                wasPublic = spot.isPublic
                fromDB = isFromDB()
                images = []
                if let _ = spot.image3 {
                    images?.append(spot.image ?? defaultImages.errorImage!)
                    images?.append(spot.image2 ?? defaultImages.errorImage!)
                    images?.append(spot.image3 ?? defaultImages.errorImage!)
                } else if let _ = spot.image2 {
                    images?.append(spot.image ?? defaultImages.errorImage!)
                    images?.append(spot.image2 ?? defaultImages.errorImage!)
                } else if let _ = spot.image {
                    images?.append(spot.image ?? defaultImages.errorImage!)
                }
                imagesUnedited = images
                initChecked = true
            }
        }
        .disabled(isSaving)
    }
    
    private func isFromDB() -> Bool {
        if spot.fromDB {
            return true
        } else {
            return false
        }
    }
    
    private var saveButtonView: some View {
        Button("Save".localized()) {
            tags = descript.findTags()
            if (isPublic && wasPublic) {
                Task {
                    isSaving = true
                    await updatePublic()
                    isSaving = false
                }
            } else if (!wasPublic && isPublic) {
                Task {
                    isSaving = true
                    await savePublic()
                    isSaving = false
                }
            } else if (wasPublic && !isPublic) {
                Task {
                    isSaving = true
                    await removePublic()
                    isSaving = false
                }
            } else {
                Task {
                    isSaving = true
                    await saveChanges()
                    isSaving = false
                }
            }
        }
        .padding(.trailing)
        .tint(.blue)
        .disabled(keepDisabled)
    }
    
    private var form: some View {
        Form {
            Section {
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
                if !fromDB {
                    displayIsPublicPrompt
                        .onAppear {
                            if !isPublicChecked {
                                isPublic = wasPublic
                                isPublicChecked = true
                            }
                        }
                }
            } header: {
                Text("Spot Name*".localized())
            } footer: {
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
            Section {
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
            } header: {
                Text("Spot Description".localized())
            } footer: {
                Text("Use # to add tags. Example: #hiking #skating".localized())
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
                            imageChanged = true
                        }
                        .onDelete { indexSet in
                            images!.remove(atOffsets: indexSet)
                            imagesUnedited!.remove(atOffsets: indexSet)
                            imageChanged = true
                        }
                    }
                }
            } header: {
                Text("Photo of Spot".localized())
            } footer: {
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
        }
    }
    
    private var keyBoardButtons: some View {
        HStack {
            Button {
                switch focusState {
                case .descript:
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
    
    private var imageToolItems: some View {
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
    
    private func saveChanges() async {
        if (imageChanged) {
            if let imageData = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
                spot.image = UIImage(data: imageData)
            }
            if images?.count == 2 {
                if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData)
                }
                spot.image3 = nil
            } else if images?.count == 3 {
                if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData)
                }
                if let imageData = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                    spot.image3 = UIImage(data: imageData)
                }
            }
            if images?.count == 1 {
                spot.image2 = nil
                spot.image3 = nil
            }
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.details = descript
        if !fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.isPublic = isPublic
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        didChange = true
        presentationMode.wrappedValue.dismiss()
    }
    
    private func savePublic() async {
        if let imageData = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
            spot.image = UIImage(data: imageData)
            var imageData2: Data? = nil
            var imageData3: Data? = nil
            if (images?.count == 3) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
                if let imageData3Check = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                    spot.image3 = UIImage(data: imageData3Check)
                    imageData3 = imageData3Check
                }
            } else if (images?.count == 2) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
            }
            do {
                let id = try await cloudViewModel.addSpotToPublic(name: name, founder: UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?", date: spot.date ?? "", locationName: spot.locationName ?? "", x: spot.x, y: spot.y, description: descript, type: tags, image: imageData, image2: imageData2, image3: imageData3, isMultipleImages: (images?.count ?? 1) - 1, customLocation: !spot.wasThere, dateObject: spot.dateObject)
                if !id.isEmpty {
                    spot.dbid = id
                    spot.isPublic = true
                } else {
                    spot.dbid = ""
                    spot.isPublic = false
                }
            } catch {
                spot.dbid = ""
                spot.isPublic = false
            }
        } else {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if images?.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images?.count == 2 {
            spot.image3 = nil
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.likes = 0
        spot.details = descript
        if !fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if !spot.isPublic {
            showingCannotSavePublicAlert = true
        }
        didChange = true
        presentationMode.wrappedValue.dismiss()
    }
    
    private func removePublic() async {
        do {
            try await cloudViewModel.deleteSpot(id: CKRecord.ID(recordName: spot.dbid ?? ""))
            spot.isPublic = false
            if (imageChanged) {
                if let imageData = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
                    spot.image = UIImage(data: imageData)
                }
                if images?.count == 2 {
                    if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                        spot.image2 = UIImage(data: imageData)
                    }
                    spot.image3 = nil
                } else if images?.count == 3 {
                    if let imageData = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                        spot.image2 = UIImage(data: imageData)
                    }
                    if let imageData = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                        spot.image3 = UIImage(data: imageData)
                    }
                }
                if images?.count == 1 {
                    spot.image2 = nil
                    spot.image3 = nil
                }
            }
            let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
            spot.name = name
            spot.details = descript
            if !fromDB {
                spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
            }
            spot.tags = tags
            do {
                try CoreDataStack.shared.context.save()
                await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
            } catch {
                showingCannotSavePrivateAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
            didChange = true
            presentationMode.wrappedValue.dismiss()
        } catch {
            spot.isPublic = true
            isPublic = true
            showingCannotDeleteAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
    }
    
    private func updatePublic() async {
        var imageData: Data? = nil
        var imageData2: Data? = nil
        var imageData3: Data? = nil
        if let imageDataCheck = cloudViewModel.compressImage(image: images?[0] ?? defaultImages.errorImage!).pngData() {
            spot.image = UIImage(data: imageDataCheck)
            imageData = imageDataCheck
            if (images?.count == 3) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
                if let imageData3Check = cloudViewModel.compressImage(image: images?[2] ?? defaultImages.errorImage!).pngData() {
                    spot.image3 = UIImage(data: imageData3Check)
                    imageData3 = imageData3Check
                }
            } else if (images?.count == 2) {
                if let imageData2Check = cloudViewModel.compressImage(image: images?[1] ?? defaultImages.errorImage!).pngData() {
                    spot.image2 = UIImage(data: imageData2Check)
                    imageData2 = imageData2Check
                }
            }
            let id = spot.dbid ?? ""
            do {
                let isSuccess = try await cloudViewModel.updateSpotPublic(id: id, newName: name, newDescription: descript, newFounder: UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?", newType: tags, imageChanged: imageChanged, image: imageData, image2: imageData2, image3: imageData3, isMultipleImages: (images?.count ?? 1) - 1)
                if isSuccess {
                    spot.isPublic = true
                } else {
                    showingCannotSaveAlert = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    return
                }
            } catch {
                showingCannotSaveAlert = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                return
            }
        } else {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        if images?.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images?.count == 2 {
            spot.image3 = nil
        }
        let hashcode = spot.name ?? "" + "\(spot.x)\(spot.y)"
        spot.name = name
        spot.details = descript
        if !fromDB {
            spot.founder = UserDefaults.standard.string(forKey: "founder") ?? spot.founder ?? "?"
        }
        spot.tags = tags
        do {
            try CoreDataStack.shared.context.save()
            await updateAppGroup(hashcode: hashcode, image: spot.image, x: spot.x, y: spot.y, name: spot.name ?? "", locatioName: spot.name ?? "")
        } catch {
            showingCannotSavePrivateAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }
        didChange = true
        presentationMode.wrappedValue.dismiss()
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
}
