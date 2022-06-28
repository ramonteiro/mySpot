import SwiftUI
import MapKit
import AlertToast

struct DetailView<T: SpotPreviewType>: View {
    
    let isSheet: Bool
    let from: Tab
    let spot: T
    @Binding var didDelete: Bool
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var tabController: TabController
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var presentEditSheet = false
    @State private var presentAccountView = false
    @State private var presentImageCloseUp = false
    @State private var presentShareSheet = false
    @State private var presentFailedToUploadAlert = false
    @State private var presentDeleteAlert = false
    @State private var presentCannotSavePublicAlert = false
    @State private var presentSavePublicSpotSpinner = false
    @State private var presentSaveSheet = false
    @State private var presentErrorDeletingSpot = false
    @State private var presentReportSpot = false
    @State private var spotInCD = false
    @State private var attemptToReport = false
    @State private var downloads = -1
    @State private var newName = ""
    @State private var expand = false
    @State private var isSaved = false
    @State private var isSaving = false
    @State private var initChecked = false
    @State private var hasReported = false
    @State private var loadingAccount = true
    @State private var reportedToast = false
    @State private var didSave = false
    @State private var copiedToast = false
    @State private var accountModel: AccountModel?
    @State private var imageOffset: CGFloat = -50
    @State private var imageSelection = 0
    @State private var images: [UIImage] = []
    private var backImage: String {
        if isSheet { return "chevron.down" }
        else { return "chevron.left" }
    }
    private var scope: String {
        if spot.isPublicPreview { return "Private".localized() }
        else { return "Public".localized() }
    }
    private var tags: [String] {
        spot.tagsPreview.components(separatedBy: ", ")
    }
    private var canModify: Bool {
        from != .playlists && spot.userIDPreview == cloudViewModel.userID
    }
    private var isAdmin: Bool {
        cloudViewModel.userID == UserDefaultKeys.admin
    }
    private var date: String {
        if let date = spot.dateObjectPreview {
            return date.toString()
        } else {
            return spot.datePreview.components(separatedBy: ";")[0]
        }
    }
    private var dateAdded: String {
        spot.dateAddedToPlaylistPreview?.toString() ?? ""
    }
    private var distance: String {
        mapViewModel.calculateDistance(from: spot.locationPreview)
    }
    
    var body: some View {
        displaySpot
            .alert("Unable To Save Spot".localized(), isPresented: $presentFailedToUploadAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Failed to upload spot. Spot is now set to private, please try again later and check internet connection.".localized())
            }
            .alert("Error Deleting Spot".localized(), isPresented: $presentErrorDeletingSpot) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Please check internet connection and try again.".localized())
            }
            .onChange(of: isSaving) { newValue in
                if newValue {
                    addDownloadToSpot()
                }
            }
            .onChange(of: tabController.playlistPopToRoot) { _ in
                if (from == .playlists) { popView() }
            }
            .onChange(of: tabController.spotPopToRoot) { _ in
                if (from == .spots) { popView() }
            }
            .onChange(of: tabController.discoverPopToRoot) { _ in
                if (from == .discover) { popView() }
            }
            .onChange(of: tabController.profilePopToRoot) { _ in
                if (from == .profile) { popView() }
            }
            .fullScreenCover(isPresented: $presentAccountView) {
                AccountDetailView(userid: spot.userIDPreview, accountModel: accountModel)
            }
            .popup(isPresented: $presentSaveSheet) {
                BottomPopupView {
                    NamePopupView(isPresented: $presentSaveSheet, text: $newName, saved: $isSaving, spotName: spot.namePreview)
                }
            }
            .toast(isPresenting: $didSave) {
                AlertToast(displayMode: .hud, type: .systemImage("checkmark", .green), title: "Saved!".localized())
            }
            .toast(isPresenting: $reportedToast) {
                AlertToast(displayMode: .hud, type: .systemImage("checkmark", .green), title: "Reported".localized())
            }
            .toast(isPresenting: $copiedToast) {
                AlertToast(displayMode: .hud, type: .systemImage("doc.text", .green), title: "Copied".localized())
            }
    }
    
    // MARK: Sub Views
    
    private var displaySpot: some View {
        ZStack {
            displayImage
            VStack {
                Spacer()
                    .frame(height: (expand ? 90 : UIScreen.screenWidth - 65))
                detailSheet
            }
            topButtonRow
            middleButtonRow
            if (presentImageCloseUp) {
                if let image = images[imageSelection] {
                    ImagePopUp(showingImage: $presentImageCloseUp, image: image)
                        .transition(.scale)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            initializeVars()
        }
        .navigationBarHidden(true)
        .background(ShareViewController(isPresenting: $presentShareSheet) {
            let av = getShareAC(id: spot.dataBaseIdPreview, name: spot.namePreview)
            av.completionWithItemsHandler = { _, _, _, _ in
                presentShareSheet = false
            }
            return av
        })
    }
    
    private var displayImage: some View {
        VStack(spacing: 0) {
            if (images.count > 1) {
                multipleImages
            } else {
                if (!images.isEmpty) {
                    if spot.isFromDiscover && spot.isMultipleImagesPreview {
                        ZStack {
                            Image(uiImage: images[0])
                                .resizable()
                                .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                                .scaledToFit()
                                .ignoresSafeArea()
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .frame(width: 30, height: 30)
                                    Spacer()
                                }
                            }
                        }
                        .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                    } else {
                        Image(uiImage: images[0])
                            .resizable()
                            .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                            .scaledToFit()
                            .ignoresSafeArea()
                    }
                } else {
                    Image(uiImage: defaultImages.errorImage!)
                        .resizable()
                        .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            }
            Spacer()
        }
        .offset(y: imageOffset)
    }
    
    private var topButtonRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 5) {
                backButtonView
                Spacer()
                if (canModify || isAdmin) {
                    deleteButton
                }
                if (spot.isPublicPreview && UIDevice.current.userInterfaceIdiom != .pad) {
                    shareButton
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 10)
            Spacer()
        }
    }
    
    private var middleButtonRow: some View {
        VStack {
            Spacer()
                .ignoresSafeArea()
                .frame(height: UIScreen.screenWidth)
            HStack {
                if spot.imagePreview != nil {
                    enLargeButton
                }
                Spacer()
                if from == .discover || from == .profile {
                    downloadButton
                } else if canModify {
                    editButton
                }
            }
            .offset(y: -60)
            Spacer()
        }
        .offset(y: -50)
    }
    
    private var downloadButton: some View {
        Button {
            withAnimation {
                presentSaveSheet = true
            }
        } label: {
            if !presentSavePublicSpotSpinner {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.title)
                    .padding(15)
                    .foregroundColor(.white)
            } else {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .background {
            Circle()
                .foregroundColor((spotInCD || isSaved) == true ? .gray : cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
        .disabled(spotInCD || isSaved)
        .padding()
        .rotationEffect(Angle(degrees: (expand ? 360 : 0)), anchor: UnitPoint(x: 0.5, y: 0.5))
        .offset(x: (expand ? 100 : 0))
    }
    
    private var multipleImages: some View {
        TabView(selection: $imageSelection) {
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index]).resizable()
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                    .scaledToFit()
                    .ignoresSafeArea()
                    .tag(index)
            }
        }
        .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
        .tabViewStyle(.page)
    }
    
    private var enLargeButton: some View {
        Button {
            withAnimation {
                presentImageCloseUp.toggle()
            }
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 15, weight: .regular))
                .padding(5)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .background(.ultraThinMaterial, ignoresSafeAreaEdges: [])
        .clipShape(Circle())
        .padding()
        .rotationEffect(Angle(degrees: (expand ? 360 : 0)), anchor: UnitPoint(x: 0.5, y: 0.5))
        .offset(x: (expand ? -50 : 0), y: -30)
        .opacity(expand ? 0 : 1)
    }
    
    private var shareButton: some View {
        Button {
            if isSheet || (from == .profile && spot.userIDPreview != cloudViewModel.userID) {
                presentShareSheet = true
            } else {
                shareSheet()
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .frame(width: 40, height: 40)
                .background { Color.black.opacity(0.4) }
                .clipShape(Circle())
        }
    }
    
    private var deleteButton: some View {
        Button {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            presentDeleteAlert.toggle()
        } label: {
            Image(systemName: "trash.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .frame(width: 40, height: 40)
                .background { Color.black.opacity(0.4) }
                .clipShape(Circle())
        }
        .alert("Are you sure you want to delete ".localized() + (spot.namePreview) + "?", isPresented: $presentDeleteAlert) {
            Button("Delete".localized(), role: .destructive) {
                if spot.isFromDiscover {
                    deleteCloudSpot()
                } else {
                    deleteMySpot()
                }
            }
        } message: {
            if spot.isFromDiscover {
                Text("Spot will be removed from 'Discover' tab and no longer sharable. If this spot is still in 'My Spots' tab, it will not be deleted there.".localized())
            } else {
                Text("Spot will be removed from 'My Spots' tab. If this spot is still in 'Discover' tab, it will not be deleted there.".localized())
            }
        }
        
    }
    
    private var backButtonView: some View {
        Button {
            popView()
        } label: {
            Image(systemName: backImage)
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .frame(width: 40, height: 40)
                .background { Color.black.opacity(0.4) }
                .clipShape(Circle())
        }
    }
    
    private var editButton: some View {
        Button {
            Task { try? await cloudViewModel.isBanned() }
            presentEditSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title)
                .padding(15)
                .foregroundColor(.white)
        }
        .background {
            Circle()
                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
        .sheet(isPresented: $presentEditSheet) {
            dismissEditSheet()
        } content: {
            if let spot = spot as? Spot {
                SpotEditSheet(spot: spot, showingCannotSavePublicAlert: $presentCannotSavePublicAlert, didSave: $didSave)
            }
        }
        .disabled(spot.isPublicPreview && !cloudViewModel.isSignedInToiCloud)
        .padding()
        .rotationEffect(Angle(degrees: (expand ? 360 : 0)), anchor: UnitPoint(x: 0.5, y: 0.5))
        .offset(x: (expand ? 100 : 0))
    }
    
    private var downloadsView: some View {
        HStack {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
            Text("\(downloads)")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
                .padding(.leading, 1)
            Spacer()
            if (!distance.isEmpty) {
                Text((distance) + " away".localized())
                    .foregroundColor(.gray)
                    .font(.system(size: 15, weight: .light))
                    .padding(.bottom, 1)
            }
        }
        .padding([.leading, .trailing], 30)
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            expandDetailsButton
            if !spot.locationNamePreview.isEmpty {
                locationNameView
            }
            middlePart
            if spot.isFromDiscover {
                downloadsView
            } else if (!distance.isEmpty) {
                HStack {
                    Text((distance) + " away".localized())
                        .foregroundColor(.gray)
                        .font(.system(size: 15, weight: .light))
                        .padding(.bottom, 1)
                        Spacer()
                }
                .padding([.leading, .trailing], 30)
            }
            if !spot.tagsPreview.isEmpty {
                tagView
            }
            descriptionView
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.namePreview, coordinate: spot.locationPreview.coordinate)], name: spot.namePreview)
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            routeMeToButton
            bottomHalf
                .padding(.bottom, 100)
        }
        .confirmationDialog("How should this spot be reported?".localized(), isPresented: $presentReportSpot) {
            Button("Offensive".localized()) {
                guard let spot = spot as? SpotFromCloud else { return }
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "offensive")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Inappropriate".localized()) {
                guard let spot = spot as? SpotFromCloud else { return }
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "inappropriate")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Spam".localized()) {
                guard let spot = spot as? SpotFromCloud else { return }
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "spam")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Dangerous".localized()) {
                guard let spot = spot as? SpotFromCloud else { return }
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "dangerous")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Cancel".localized(), role: .cancel) { }
        }
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .cornerRadius(radius: 20, corners: [.topLeft, .topRight])
                .mask(Rectangle().padding(.top, -20))
        }
    }
    
    private var middlePart: some View {
        VStack(spacing: 4) {
            nameView
            dateView
        }
    }
    
    private var descriptionView: some View {
        HStack(spacing: 5) {
            Text(spot.descriptionPreview)
            Spacer()
        }
        .padding(.top, 10)
        .padding([.leading, .trailing], 30)
        .onTapGesture {
            copyDescription()
        }
    }
    
    private var nameView: some View {
        HStack {
            Text(spot.namePreview)
                .font(.system(size: 45, weight: .heavy))
            Spacer()
        }
        .padding(.leading, 30)
        .padding(.trailing, 5)
    }
    
    @ViewBuilder
    private var accountRowView: some View {
        if !loadingAccount {
            if let accountModel = accountModel {
                Button {
                    tapAccountButton()
                } label: {
                    HStack {
                        if let image = accountModel.image {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Color.gray
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        }
                        Text(accountModel.name)
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
        }
    }
    
    private var dateView: some View {
        HStack {
            accountRowView
            Spacer()
            Text(date)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
        }
        .padding([.leading, .trailing], 30)
    }
    
    private var expandDetailsButton: some View {
        Image(systemName: (expand ? "x.circle.fill" : "arrow.up.circle.fill"))
            .resizable()
            .frame(width: (expand ? 50 : 30), height: (expand ? 50 : 30))
            .foregroundColor(Color.secondary)
            .onTapGesture {
                expandSheet()
            }
            .padding(.top, 5)
    }
    
    private var addedByView: some View {
        HStack {
            Text("Added By: ".localized() + (spot.addedByPreview ?? ""))
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
            Spacer()
            Text(dateAdded)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
        }
        .padding([.leading, .trailing], 30)
        .padding(.top, 1)
    }
    
    private var locationNameView: some View {
        HStack {
            Image(systemName: (spot.customLocationPreview ? "mappin" : "figure.wave"))
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
            Text(spot.locationNamePreview)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
                .padding(.leading, 1)
            Spacer()
        }
        .padding([.leading, .trailing], 30)
    }
    
    private var tagView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .regular))
                        .lineLimit(2)
                        .foregroundColor(.white)
                        .padding(5)
                        .background(.tint, ignoresSafeAreaEdges: [])
                        .cornerRadius(5)
                }
            }
        }
        .padding([.leading, .trailing], 30)
        .offset(y: 5)
    }
    
    private var routeMeToButton: some View {
        Button {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: spot.locationPreview.coordinate))
            routeMeTo.name = spot.namePreview
            routeMeTo.openInMaps(launchOptions: nil)
        } label: {
            HStack {
                Image(systemName: "location.fill")
                Text(spot.namePreview)
            }
            .padding(.horizontal)
        }
        .buttonStyle(.borderedProminent)
        .padding(.top, 10)
        .padding([.leading, .trailing], 30)
    }
    
    private var copyIdButton: some View {
        Button {
            copyId()
        } label: {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                Text("Share ID".localized())
            }
            .padding(.horizontal)
        }
        .buttonStyle(.borderedProminent)
        .padding([.top, .bottom], 10)
        .padding([.leading, .trailing], 30)
    }
    
    private var bottomHalf: some View {
        VStack {
            if spot.isPublicPreview && !spot.dataBaseIdPreview.isEmpty {
                copyIdButton
            }
            if isAdmin && spot.isFromDiscover {
                Button {
                    Task {
                        guard let spot = spot as? SpotFromCloud else { return }
                        await cloudViewModel.addDownloads(spot: spot)
                    }
                } label: {
                    Text("add random downloads")
                }
            }
            if spot.isFromDiscover {
                if (!attemptToReport) {
                    if !hasReported {
                        Button {
                            presentReportSpot = true
                        } label: {
                            HStack {
                                Text("Report Spot".localized())
                                Image(systemName: "exclamationmark.triangle.fill")
                            }
                        }
                        .padding([.top, .bottom], 10)
                    } else {
                        HStack {
                            Text("Report Received".localized())
                            Image(systemName: "checkmark.square.fill")
                        }
                        .padding([.top, .bottom], 10)
                        .onAppear {
                            reportedToast = true
                        }
                    }
                } else {
                    ProgressView().progressViewStyle(.circular)
                        .padding([.top, .bottom], 10)
                }
            } else {
                isPublicView
            }
        }
    }
    
    private var isPublicView: some View {
        HStack {
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
            Text("\(scope)")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color.gray)
            if (spot.isPublicPreview && downloads > -1) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(downloads)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            fetchDownloads()
        }
    }
    
    // MARK: - Functions
    
    private func loadAccount() {
        if loadingAccount {
            Task {
                do {
                    accountModel = try await cloudViewModel.fetchAccount(userid: spot.userIDPreview)
                    withAnimation {
                        loadingAccount = false
                    }
                    accountModel?.image = await cloudViewModel.fetchAccountImage(userid: accountModel?.id ?? "error")
                } catch {
                    print("failed to load user account")
                }
            }
        }
    }
    
    private func loadMySpotImages() {
        if !images.isEmpty { return }
        images.append(spot.imagePreview ?? defaultImages.errorImage!)
        if let image2 = spot.image2Preview {
            images.append(image2)
        }
        if let image3 = spot.image3Preview {
            images.append(image3)
        }
    }
    
    private func getShareAC(id: String, name: String) -> UIActivityViewController {
        return UIActivityViewController(activityItems: ["Check out, \"".localized() + name + "\" on My Spot! ".localized(), URL(string: "myspot://" + (id)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ".localized(), URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
    }
    
    private func deleteMySpot() {
        if let i = spots.firstIndex(where: { $0.id?.uuidString == spot.parentIDPreview }) {
            CoreDataStack.shared.deleteSpot(spots[i])
            didDelete = true
            popView()
        }
    }
    
    private func popView() {
        if isSheet {
            imageOffset = 0
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func dismissEditSheet() {
        if presentCannotSavePublicAlert {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            presentFailedToUploadAlert.toggle()
            presentCannotSavePublicAlert = false
        }
    }
    
    private func copyDescription() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let pasteboard = UIPasteboard.general
        pasteboard.string = spot.descriptionPreview
        copiedToast = true
    }
    
    private func expandSheet() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation {
            expand.toggle()
        }
    }
    
    private func copyId() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        let pasteboard = UIPasteboard.general
        pasteboard.string = "myspot://" + (spot.dataBaseIdPreview)
        copiedToast = true
    }
    
    private func fetchDownloads() {
        if spot.isPublicPreview {
            Task {
                do {
                    let download = try await cloudViewModel.getLikes(idString: spot.dataBaseIdPreview)
                    if let download = download {
                        downloads = Int(download)
                    }
                } catch {
                    print("failed to find downloads")
                }
            }
        }
    }
    
    private func isSpotInCoreData() -> Bool {
        var isInSpots = false
        spots.forEach { s in
            if s.dbid == spot.dataBaseIdPreview {
                isInSpots = true
                return
            }
        }
        return isInSpots
    }
    
    private func save() async {
        let newSpot = Spot(context: CoreDataStack.shared.context)
        newSpot.founder = spot.founderPreview
        newSpot.details = spot.descriptionPreview
        newSpot.image = images[0]
        if images.count == 3 {
            newSpot.image2 = images[1]
            newSpot.image3 = images[2]
        } else if images.count == 2 {
            newSpot.image2 = images[1]
        }
        newSpot.isShared = false
        newSpot.userId = spot.userIDPreview
        newSpot.locationName = spot.locationNamePreview
        newSpot.name = (newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? spot.namePreview : newName)
        newSpot.x = spot.locationPreview.coordinate.latitude
        newSpot.y = spot.locationPreview.coordinate.longitude
        newSpot.isPublic = false
        if spot.userIDPreview != cloudViewModel.userID {
            newSpot.fromDB = true
        } else {
            newSpot.fromDB = false
        }
        newSpot.tags = spot.tagsPreview
        newSpot.date = spot.datePreview
        if let dateObject = spot.dateObjectPreview {
            newSpot.dateObject = dateObject
        } else {
            newSpot.dateObject = nil
        }
        if spot.customLocationPreview {
            newSpot.wasThere = false
        } else {
            newSpot.wasThere = true
        }
        newSpot.id = UUID()
        newSpot.dbid = spot.dataBaseIdPreview
        CoreDataStack.shared.save()
        let hashcode = newSpot.name ?? "" + "\(newSpot.x)\(newSpot.y)"
        await updateAppGroup(hashcode: hashcode, image: newSpot.image, x: newSpot.x, y: newSpot.y, name: newSpot.name ?? "", locatioName: newSpot.name ?? "")
        isSaved = true
    }
    
    private func updateAppGroup(hashcode: String,
                                image: UIImage?,
                                x: Double,
                                y: Double,
                                name: String,
                                locatioName: String) async {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        guard var xArr: [Double] = userDefaults?.object(forKey: "spotXs") as? [Double] else { return }
        guard var yArr: [Double] = userDefaults?.object(forKey: "spotYs") as? [Double] else { return }
        guard var nameArr: [String] = userDefaults?.object(forKey: "spotNames") as? [String] else { return }
        guard var locationNameArr: [String] = userDefaults?.object(forKey: "spotLocationName") as? [String] else { return }
        guard var imgArr: [Data] = userDefaults?.object(forKey: "spotImgs") as? [Data] else { return }
        guard let data = ImageCompression().compress(image: image ?? defaultImages.errorImage!) else { return }
        let encoded = try! PropertyListEncoder().encode(data)
        locationNameArr.append(locatioName)
        nameArr.append(name)
        xArr.append(x)
        yArr.append(y)
        imgArr.append(encoded)
        userDefaults?.set(locationNameArr, forKey: "spotLocationName")
        userDefaults?.set(xArr, forKey: "spotXs")
        userDefaults?.set(yArr, forKey: "spotYs")
        userDefaults?.set(nameArr, forKey: "spotNames")
        userDefaults?.set(imgArr, forKey: "spotImgs")
        userDefaults?.set(imgArr.count, forKey: "spotCount")
    }
    
    private func addDownloadToSpot() {
        Task {
            if let spot = spot as? SpotFromCloud {
                presentSavePublicSpotSpinner = true
                let didLike = await cloudViewModel.likeSpot(spot: spot)
                if (didLike) {
                    DispatchQueue.main.async {
                        downloads += 1
                    }
                }
            }
            await save()
            presentSavePublicSpotSpinner = false
        }
    }
    
    private func loadCloudImages() {
        spotInCD = isSpotInCoreData()
        if let image1 = spot.imagePreview {
            images.append(image1)
        } else {
            Task {
                let id = spot.dataBaseIdPreview
                let fetchedImages = await cloudViewModel.fetchMainImage(id: id)
                if let image = fetchedImages {
                    images.append(image)
                }
            }
        }
        if let image2 = spot.image2Preview {
            images.append(image2)
        }
        if let image3 = spot.image3Preview {
            images.append(image3)
        }
        if images.count < 2 {
            Task {
                let id = spot.dataBaseIdPreview
                let fetchedImages: [UIImage?] = await cloudViewModel.fetchImages(id: id)
                if !fetchedImages.isEmpty {
                    fetchedImages.forEach { image in
                        if let image = image {
                            self.images.append(image)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteCloudSpot() {
        let spotID = spot.dataBaseIdPreview
        Task {
            do {
                try await cloudViewModel.deleteSpot(id: spotID)
                DispatchQueue.main.async {
                    spots.forEach { i in
                        if i.dbid == spotID {
                            i.isPublic = false
                            CoreDataStack.shared.save()
                            return
                        }
                    }
                    didDelete = true
                    popView()
                }
            } catch {
                presentErrorDeletingSpot = true
            }
        }
    }
    
    private func shareSheet() {
        let activityView = getShareAC(id: spot.dataBaseIdPreview, name: spot.namePreview)
        
        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }
        
        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }
        
    }
    
    private func initializeVars() {
        if !initChecked {
            loadAccount()
            downloads = spot.downloadsPreview
            if spot.isFromDiscover {
                loadCloudImages()
            } else {
                loadMySpotImages()
            }
            initChecked = true
        }
    }
    
    private func tapAccountButton() {
        if cloudViewModel.userID == spot.userIDPreview {
            tabController.open(.profile)
            if isSheet {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.keyWindow?.rootViewController?.dismiss(animated: true)
                }
            }
        } else if from == .profile {
            presentationMode.wrappedValue.dismiss()
        } else {
            presentAccountView.toggle()
        }
    }
}
