//
//  CreateAccountView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/3/22.
//

import SwiftUI
import Combine

struct CreateAccountView: View {
    
    @State private var nameChecked = false
    @State private var pronounChecked = false
    @State private var instaChecked = false
    @State private var youtubeChecked = false
    @State private var tiktokChecked = false
    @State private var emailChecked = false
    @State private var imageWasChanged = false
    
    let accountModel: AccountModel?
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var youtube: String = ""
    @State private var tiktok: String = ""
    @State private var insta: String = ""
    @State private var email: String = ""
    @State private var pronoun: String = ""
    @State private var image: UIImage?
    @State private var presentSaveAlert: Bool = false
    @State private var presentUpdateAlert: Bool = false
    @State private var presentAddImageAlert: Bool = false
    @State private var isSaving: Bool = false
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
                    savingView
                }
            }
            .navigationTitle("Create Account".localized())
            .navigationViewStyle(.stack)
            .onAppear {
                checkForExistingAccountModel()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    keyboardView
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                   saveButton
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
            .onSubmit {
                moveDown()
            }
            .alert("Unable To Create Account".localized(), isPresented: $presentSaveAlert) {
                Button("OK".localized(), role: .cancel) { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Failed to create account, you will be asked to create your account later.".localized())
            }
            .alert("Failed To Update Account".localized(), isPresented: $presentUpdateAlert) {
                Button("OK".localized(), role: .cancel) { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text("Please check internet and try again".localized() + ".")
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
                open(item: item)
            }
        }
    }
    
    // MARK: - Sub Views
    
    @ViewBuilder
    private var cancelButton: some View {
        if accountModel != nil {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Cancel".localized())
            }
            .disabled(isSaving)
        }
    }
    
    private var saveButton: some View {
        Button {
            if accountModel == nil {
                Task {
                    await save()
                }
            } else {
                Task {
                    await update()
                }
            }
        } label: {
            Text("Save".localized())
                .foregroundColor(.blue)
        }
        .disabled(disableSave)
    }
    
    @ViewBuilder
    private func open(item: ActiveSheet) -> some View {
        switch item {
        case .cameraSheet:
            TakePhoto(selectedImage: $image)
                .onDisappear {
                    if (image != nil) {
                        activeSheet = .cropperSheet
                        imageWasChanged = true
                    } else {
                        activeSheet = nil
                    }
                }
                .ignoresSafeArea()
        case .cameraRollSheet:
            ChoosePhoto() { image in
                self.image = image
                activeSheet = .cropperSheet
                imageWasChanged = true
            }
            .ignoresSafeArea()
        case .cropperSheet:
            MantisPhotoCropper(selectedImage: $image)
                .ignoresSafeArea()
        }
    }
    
    private var savingView: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
                .opacity(0.5)
            ProgressView("Saving".localized())
                .progressViewStyle(.circular)
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
        .disabled(focusState == .youtube)
    }
    
    private var keyboardView: some View {
        HStack {
            upButton
            downButton
            Spacer()
            Button("Done".localized()) {
                focusState = nil
            }
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
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
    
    private var addImageButton: some View {
        HStack {
            Spacer()
            Button {
                presentAddImageAlert = true
            } label: {
                imageView
            }
            Spacer()
        }
        .listRowBackground(Color(uiColor: UIColor.secondarySystemBackground))
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
                Button {
                    playInYoutube(youtubeId: "XHWUx5ANh_o?feature=share")
                } label: {
                    Text("Enter Account ID".localized())
                }
            }
        }
        
    }
    
    private var displayNamePrompt: some View {
        TextField("Enter Name".localized(), text: $name)
            .onAppear {
                setName()
            }
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
            .onAppear {
                setPronoun()
            }
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
            .onAppear {
                setEmail()
            }
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
            .onAppear {
                setTiktok()
            }
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
            .onAppear {
                setInsta()
            }
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
            .onAppear {
                setYoutube()
            }
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
    
    // MARK: - Functions
    
    private func setName() {
        if let accountModel = accountModel {
            if !nameChecked {
                name = accountModel.name
                nameChecked = true
            }
        }
    }
    
    private func setPronoun() {
        if let accountModel = accountModel {
            if !pronounChecked {
                pronoun = accountModel.pronouns ?? ""
                pronounChecked = true
            }
        }
    }
    
    private func setEmail() {
        if let accountModel = accountModel {
            if !emailChecked {
                email = accountModel.email ?? ""
                emailChecked = true
            }
        }
    }
    
    private func setTiktok() {
        if let accountModel = accountModel {
            if !tiktokChecked {
                tiktok = accountModel.tiktok ?? ""
                tiktokChecked = true
            }
        }
    }
    
    private func setInsta() {
        if let accountModel = accountModel {
            if !instaChecked {
                insta = accountModel.insta ?? ""
                instaChecked = true
            }
        }
    }
    
    private func setYoutube() {
        if let accountModel = accountModel {
            if !youtubeChecked {
                youtube = accountModel.youtube ?? ""
                youtubeChecked = true
            }
        }
    }
    
    private func moveDown() {
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
    }
    
    private func moveUp() {
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
    }
    
    private func save() async {
        UserDefaults.standard.set(name, forKey: "founder")
        guard let image = image else { return }
        guard let imageData = cloudViewModel.compressImage(image: image).pngData() else { return }
        isSaving = true
        do {
            try await cloudViewModel.addNewAccount(userid: cloudViewModel.userID, name: name, pronoun: pronoun, image: imageData, bio: bio, email: email, youtube: youtube, tiktok: tiktok, insta: insta)
            try? await cloudViewModel.getMemberSince(fromid: cloudViewModel.userID)
            isSaving = false
            presentationMode.wrappedValue.dismiss()
        } catch {
            isSaving = false
            presentSaveAlert.toggle()
        }
    }
    
    private func update() async {
        isSaving = true
        if let accountModel = accountModel {
            if imageWasChanged {
                guard let image = image else { return }
                guard let imageData = cloudViewModel.compressImage(image: image).pngData() else { return }
                isSaving = true
                do {
                    try await cloudViewModel.updateAccount(id: accountModel.record.recordID, newName: name, newBio: bio, newPronouns: pronoun, newEmail: email, newTiktok: tiktok, image: imageData, newInsta: insta, newYoutube: youtube)
                    isSaving = false
                    UserDefaults.standard.set(name, forKey: "founder")
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    isSaving = false
                    presentUpdateAlert.toggle()
                }
            } else {
                isSaving = true
                do {
                    try await cloudViewModel.updateAccount(id: accountModel.record.recordID, newName: name, newBio: bio, newPronouns: pronoun, newEmail: email, newTiktok: tiktok, image: nil, newInsta: insta, newYoutube: youtube)
                    isSaving = false
                    UserDefaults.standard.set(name, forKey: "founder")
                    presentationMode.wrappedValue.dismiss()
                } catch {
                    isSaving = false
                    presentUpdateAlert.toggle()
                }
            }
            isSaving = false
        } else {
            isSaving = false
            presentUpdateAlert.toggle()
        }
    }
    
    private func checkForExistingAccountModel() {
        if let accountModel = accountModel {
            if image == nil {
                image = accountModel.image
                if let b = accountModel.bio {
                    bio = b
                }
            }
        }
    }
    
    func playInYoutube(youtubeId: String) {
        if let youtubeURL = URL(string: "youtube://\(youtubeId)"),
            UIApplication.shared.canOpenURL(youtubeURL) {
            // redirect to app
            UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
        } else if let youtubeURL = URL(string: "https://www.youtube.com/watch?v=\(youtubeId)") {
            // redirect through safari
            UIApplication.shared.open(youtubeURL, options: [:], completionHandler: nil)
        }
    }
}
