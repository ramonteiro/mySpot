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
    @State private var imageChanged = false
    @State private var showingAddImageAlert = false
    @State private var didCancel = false
    @State private var imageTemp: UIImage?
    @State private var images: [UIImage]?
    
    
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
    
    private var keepDisabled: Bool {
        (fromDB && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || (!fromDB && (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) || (fromDB && !wasPublic && (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || founder.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) || images?.isEmpty ?? true
    }
    
    var body: some View {
        NavigationView {
            if ((wasPublic && networkViewModel.hasInternet) || (!wasPublic)) {
                Form {
                    Section {
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
                    } header: {
                        Text("Spot Name*")
                    } 
                    if !fromDB || !wasPublic {
                        Section {
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
                        } header: {
                            Text("Founder's Name*")
                        }
                        if (!wasPublic) {
                            Section {
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
                            } header: {
                                Text("Share Spot")
                            } footer: {
                                Text("Public spots are shown in discover tab to other users.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
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
                        Text("Spot Description")
                    } footer: {
                        Text("Use # to add tags. Example: #hiking #skating")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .onAppear {
                        descript = spot.details ?? ""
                    }
                    Section {
                        if (images?.count ?? 0 > 0) {
                            List {
                                ForEach(images ?? [defaultImages.errorImage!], id: \.self) { images in
                                    if let images = images {
                                        HStack {
                                            Spacer()
                                            Image(uiImage: images)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: UIScreen.screenWidth / 2, alignment: .center)
                                                .cornerRadius(10)
                                            Spacer()
                                        }
                                    }
                                }
                                .onMove { indexSet, offset in
                                    images!.move(fromOffsets: indexSet, toOffset: offset)
                                    imageChanged = true
                                }
                                .onDelete { indexSet in
                                    images!.remove(atOffsets: indexSet)
                                    imageChanged = true
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
                        if (fromDB && wasPublic) {
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
                                    images?.append(imageTemp ?? defaultImages.errorImage!)
                                    imageChanged = true
                                }
                                imageTemp = nil
                            }
                            .ignoresSafeArea()
                    }
                }
                .navigationTitle(name)
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
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Save") {
                            if (wasPublic) {
                                isPublic = true
                            }
                            tags = descript.findTags()
                            if (isPublic && wasPublic) {
                                updatePublic()
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
                                    if (fromDB && wasPublic) {
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
                                    if (fromDB && wasPublic) {
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
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        spot.tags = tags
        try? moc.save()
    }
    
    private func savePublic() {
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
            let id = cloudViewModel.addSpotToPublic(name: name, founder: founder, date: spot.date ?? "", locationName: spot.locationName ?? "", x: spot.x, y: spot.y, description: descript, type: tags, image: imageData, image2: imageData2, image3: imageData3)
            spot.dbid = id
        } else {
            return
        }
        if spot.dbid == "" {
            return
        }
        if images?.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images?.count == 2 {
            spot.image3 = nil
        }
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        spot.tags = tags
        try? moc.save()
    }
    
    private func updatePublic() {
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
        } else {
            return
        }
        cloudViewModel.updateSpotPublic(spot: spot, newName: name, newDescription: descript, newFounder: founder, newType: tags, imageChanged: imageChanged, image: imageData, image2: imageData2, image3: imageData3)
        if images?.count == 1 {
            spot.image2 = nil
            spot.image3 = nil
        } else if images?.count == 2 {
            spot.image3 = nil
        }
        spot.name = name
        spot.details = descript
        spot.founder = founder
        spot.isPublic = isPublic
        spot.tags = tags
        try? moc.save()
    }
    
    private var displayIsPublicPrompt: some View {
        Toggle("Public", isOn: $isPublic)
    }
}
