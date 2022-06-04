//
//  CreateAccountView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/3/22.
//

import SwiftUI
import Combine

struct CreateAccountView: View {
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var youtube: String = ""
    @State private var tiktok: String = ""
    @State private var insta: String = ""
    @State private var email: String = ""
    @State private var pronoun: String = ""
    @State private var image: UIImage?
    @State private var saveAlert: Bool = false
    @State private var isSaving: Bool = false
    @State private var showingAddImageAlert: Bool = false
    @FocusState private var focusState: Field?
    @State private var activeSheet: ActiveSheet?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var cloudViewModel: CloudKitViewModel
    
    private var disableSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image == nil || isSaving
    }
    
    private enum Field {
        case name
        case pronoun
        case bio
        case email
        case tiktok
        case insta
        case youtube
    }
    
    private enum ActiveSheet: Identifiable {
        case cameraSheet
        case cameraRollSheet
        case cropperSheet
        var id: Int {
            hashValue
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                textForm
                if isSaving {
                    Color.black
                        .ignoresSafeArea()
                        .opacity(0.5)
                    ProgressView("Saving".localized())
                        .progressViewStyle(.circular)
                }
            }
            .navigationTitle("Create Account".localized())
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    keyboardView
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await save()
                        }
                    } label: {
                        Text("Save".localized())
                    }
                    .disabled(disableSave)
                }
            }
            .onSubmit {
                switch focusState {
                case .name:
                    focusState = .pronoun
                case .pronoun:
                    focusState = .bio
                case .bio:
                    focusState = .email
                case .email:
                    focusState = .tiktok
                case .tiktok:
                    focusState = .insta
                case .insta:
                    focusState = .youtube
                default:
                    focusState = nil
                }
            }
            .alert("Unable To Create Account".localized(), isPresented: $saveAlert) {
                Button("OK".localized(), role: .cancel) { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Failed to create account, you will be asked to create your account later.".localized())
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
                    TakePhoto(selectedImage: $image)
                        .onDisappear {
                            if (image != nil) {
                                activeSheet = .cropperSheet
                            } else {
                                activeSheet = nil
                            }
                        }
                        .ignoresSafeArea()
                case .cameraRollSheet:
                    ChoosePhoto() { image in
                        self.image = image
                        activeSheet = .cropperSheet
                    }
                    .ignoresSafeArea()
                case .cropperSheet:
                    MantisPhotoCropper(selectedImage: $image)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    private var keyboardView: some View {
        HStack {
            Button {
                switch focusState {
                case .youtube:
                    focusState = .insta
                case .insta:
                    focusState = .tiktok
                case .tiktok:
                    focusState = .email
                case .email:
                    focusState = .bio
                case .bio:
                    focusState = .pronoun
                case .pronoun:
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
                case .insta:
                    focusState = .youtube
                case .tiktok:
                    focusState = .insta
                case .email:
                    focusState = .tiktok
                case .bio:
                    focusState = .email
                case .name:
                    focusState = .pronoun
                case .pronoun:
                    focusState = .bio
                default:
                    focusState = nil
                }
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(focusState == .youtube)
            Spacer()
            Button("Done".localized()) {
                focusState = nil
            }
        }
    }
    
    private var addImageButton: some View {
        HStack {
            Spacer()
            Button {
                showingAddImageAlert = true
            } label: {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "camera")
                        .resizable()
                        .frame(width: 60, height: 45)
                        .padding(30)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke((colorScheme == .dark ? .white : .black), lineWidth: 4)
                        )
                }
            }
            Spacer()
        }
    }
    
    private var textForm: some View {
        Form {
            Section {
                addImageButton
            }
            Section {
                displayNamePrompt
            } header: {
                Text("Name*".localized())
            }
            Section {
                displayPronounPrompt
            } header: {
                Text("Pronouns".localized())
            }
            Section {
                displayBioPrompt
            } header: {
                Text("Bio".localized())
            }
            Section {
                displayEmailPrompt
            } header: {
                Text("Email".localized())
            } footer: {
                Text("Used for account recovery only".localized())
            }
            Section {
                displayTiktokPrompt
            } header: {
                Text("Tiktok".localized())
            } footer: {
                Text("Enter Account Username".localized())
            }
            Section {
                displayInstaPrompt
            } header: {
                Text("Instagram".localized())
            } footer: {
                Text("Enter Account Username".localized())
            }
            Section {
                displayYoutubePrompt
            } header: {
                Text("Youtube".localized())
            } footer: {
                Text("Enter Account Username".localized())
            }
        }
        
    }
    
    private var displayNamePrompt: some View {
        TextField("Enter Name".localized(), text: $name)
            .focused($focusState, equals: .name)
            .submitLabel(.next)
            .textContentType(.givenName)
            .onReceive(Just(name)) { _ in
                if (name.count > MaxCharLength.fullName) {
                    name = String(name.prefix(MaxCharLength.fullName))
                }
            }
    }
    
    private var displayPronounPrompt: some View {
        TextField("Optional".localized(), text: $pronoun)
            .focused($focusState, equals: .pronoun)
            .submitLabel(.next)
            .onReceive(Just(pronoun)) { _ in
                if (pronoun.count > MaxCharLength.names) {
                    pronoun = String(pronoun.prefix(MaxCharLength.names))
                }
            }
    }
    
    private var displayBioPrompt: some View {
        ZStack {
            TextEditor(text: $bio)
            Text(bio).opacity(0).padding(.all, 8)
        }
        .focused($focusState, equals: .bio)
        .onReceive(Just(bio)) { _ in
            if (bio.count > MaxCharLength.bio) {
                bio = String(bio.prefix(MaxCharLength.bio))
            }
        }
    }
    
    private var displayEmailPrompt: some View {
        TextField("Optional".localized(), text: $email)
            .focused($focusState, equals: .email)
            .submitLabel(.next)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .onReceive(Just(email)) { _ in
                if (email.count > MaxCharLength.email) {
                    email = String(email.prefix(MaxCharLength.email))
                }
            }
    }
    
    private var displayTiktokPrompt: some View {
        TextField("Optional".localized(), text: $tiktok)
            .focused($focusState, equals: .tiktok)
            .submitLabel(.next)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .onReceive(Just(tiktok)) { _ in
                if (tiktok.count > MaxCharLength.email) {
                    tiktok = String(tiktok.prefix(MaxCharLength.email))
                }
            }
    }
    
    private var displayInstaPrompt: some View {
        TextField("Optional".localized(), text: $insta)
            .focused($focusState, equals: .insta)
            .submitLabel(.next)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .onReceive(Just(insta)) { _ in
                if (insta.count > MaxCharLength.email) {
                    insta = String(insta.prefix(MaxCharLength.email))
                }
            }
    }
    
    private var displayYoutubePrompt: some View {
        TextField("Optional".localized(), text: $youtube)
            .focused($focusState, equals: .youtube)
            .submitLabel(.done)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .onReceive(Just(youtube)) { _ in
                if (youtube.count > MaxCharLength.email) {
                    youtube = String(youtube.prefix(MaxCharLength.email))
                }
            }
    }
    
    private func save() async {
        guard let image = image else { return }
        guard let imageData = cloudViewModel.compressImage(image: image).pngData() else { return }
        isSaving = true
        let totalDownloads = try? await cloudViewModel.getTotalDownloads(fromid: cloudViewModel.userID)
        do {
            let totalSpots = try await cloudViewModel.getTotalSpots(fromid: cloudViewModel.userID)
            try await cloudViewModel.addNewAccount(userid: cloudViewModel.userID, name: name, pronoun: pronoun, image: imageData, bio: bio, email: email, youtube: youtube, tiktok: tiktok, insta: insta)
            await saveToDefaults(imageData: imageData, totalSpots: totalSpots, totalDownloads: totalDownloads)
            isSaving = false
            presentationMode.wrappedValue.dismiss()
        } catch {
            isSaving = false
            saveAlert.toggle()
        }
    }
    
    private func saveToDefaults(imageData: Data, totalSpots: Int?, totalDownloads: Int?) async {
        let def = UserDefaults.standard
        def.set(name, forKey: Account.name)
        def.set(imageData, forKey: Account.image)
        def.set(totalSpots ?? 0, forKey: Account.totalSpots)
        def.set(totalDownloads ?? 0, forKey: Account.downloads)
        if pronoun.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.pronouns)
        } else {
            def.set(pronoun, forKey: Account.pronouns)
        }
        if bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.bio)
        } else {
            def.set(bio, forKey: Account.bio)
        }
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.email)
        } else {
            def.set(email, forKey: Account.email)
        }
        if tiktok.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.tiktok)
        } else {
            def.set(tiktok, forKey: Account.tiktok)
        }
        if insta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.insta)
        } else {
            def.set(insta, forKey: Account.insta)
        }
        if youtube.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            def.removeObject(forKey: Account.youtube)
        } else {
            def.set(youtube, forKey: Account.youtube)
        }
    }
}
