//
//  DiscoverDetailAccountSpots.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/4/22.
//

import SwiftUI
import Combine
import MapKit
import CoreData

struct DiscoverDetailAccountSpots: View {
    
    var index: Int
    @Binding var spotsFromCloud: [SpotFromCloud]
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.colorScheme) var colorScheme
    
    let canShare: Bool
    @State private var backImage = "chevron.left"
    @State private var mySpot = false
    @State private var didCopy = false
    let myAccount: Bool
    @State private var didCopyDescription = false
    @State private var distance: String = ""
    @State private var deleteAlert = false
    @State private var showingReportAlert = false
    @State private var selection = 0
    @State private var showSaveAlert = false
    @State private var showingCannotSavePrivateAlert = false
    @State private var isSaving = false
    @State private var newName = ""
    @State private var isSaved: Bool = false
    @State private var imageOffset: CGFloat = -50
    @State private var tags: [String] = []
    @State private var images: [UIImage] = []
    @State private var showingImage = false
    @State private var showingSaveSheet = false
    @State private var noType = false
    @State private var expand = false
    @State private var spotInCD = false
    @State private var dateToShow = ""
    @State private var attemptToReport = false
    @FocusState private var nameIsFocused: Bool
    @State private var hasReported: Bool = false
    @State private var isShare = false
    
    var body: some View {
        ZStack {
            ZStack {
                displayImage
                    .offset(y: imageOffset)
                VStack {
                    Spacer()
                        .frame(height: (expand ? 90 : UIScreen.screenWidth - 65))
                    detailSheet
                }
                topButtonRow
                middleButtonRow
                    .offset(y: -50)
                if (showingImage) {
                    ImagePopUp(showingImage: $showingImage, image: images[selection])
                        .transition(.scale)
                }
            }
            .ignoresSafeArea(.all, edges: (canShare ? .top : [.top, .bottom]))
            .if(myAccount) { view in
                view.onChange(of: tabController.profilePopToRoot) { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .if(!myAccount) { view in
                view.onChange(of: tabController.discoverPopToRoot) { _ in
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onChange(of: isSaving) { newValue in
                if newValue {
                    Task {
                        showSaveAlert = true
                        let spot = spotsFromCloud[index]
                        let didLike = await cloudViewModel.likeSpot(spot: spot)
                        if (didLike) {
                            DispatchQueue.main.async {
                                spotsFromCloud[index].likes += 1
                            }
                        }
                        await save()
                        showSaveAlert = false
                    }
                }
            }
            .onAppear {
                mySpot = cloudViewModel.isMySpot(user: spotsFromCloud[index].userID)
                tags = spotsFromCloud[index].type.components(separatedBy: ", ")
                
                // check for images
                let url = spotsFromCloud[index].imageURL
                if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    self.images.append(image)
                }
                Task {
                    let id = spotsFromCloud[index].record.recordID.recordName
                    let fetchedImages: [UIImage?] = await cloudViewModel.fetchImages(id: id)
                    if !fetchedImages.isEmpty {
                        fetchedImages.forEach { image in
                            if let image = image {
                                self.images.append(image)
                            }
                        }
                    }
                }
                
                
                isSaving = false
                newName = ""
                cloudViewModel.canRefresh = false
            }
            
        }
        .popup(isPresented: $showingSaveSheet) {
            BottomPopupView {
                NamePopupView(isPresented: $showingSaveSheet, text: $newName, saved: $isSaving, spotName: spotsFromCloud[index].name)
            }
        }
        .alert("Unable To Save Spot".localized(), isPresented: $showingCannotSavePrivateAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Failed to save spot. Please try again.".localized())
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all, edges: (canShare ? .top : [.top, .bottom]))
        .onAppear {
            noType = spotsFromCloud[index].type.isEmpty
            spotInCD = isSpotInCoreData()
            if (canShare) {
                backImage = "chevron.left"
            } else {
                backImage = "chevron.down"
            }
        }
        .background(ShareViewController(isPresenting: $isShare) {
            let av = getShareAC(id: spotsFromCloud[index].record.recordID.recordName, name: spotsFromCloud[index].name)
            av.completionWithItemsHandler = { _, _, _, _ in
                isShare = false
            }
            return av
        })
    }
    
    private var middleButtonRow: some View {
        VStack {
            Spacer()
                .ignoresSafeArea()
                .frame(height: UIScreen.screenWidth)
            HStack {
                enlargeImageButton
                    .padding()
                    .rotationEffect(Angle(degrees: (expand ? 360 : 0)), anchor: UnitPoint(x: 0.5, y: 0.5))
                    .offset(x: (expand ? -50 : 0), y: -30)
                    .opacity(expand ? 0 : 1)
                Spacer()
                downloadButton
                    .padding()
                    .rotationEffect(Angle(degrees: (expand ? 360 : 0)), anchor: UnitPoint(x: 0.5, y: 0.5))
                    .offset(x: (expand ? 100 : 0))
            }
            .offset(y: -60)
            Spacer()
        }
    }
    
    private var topButtonRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                backButton
                Spacer()
                if (mySpot) {
                    deleteButton
                }
                if (UIDevice.current.userInterfaceIdiom != .pad) {
                    canShareButton
                }
            }
            .padding(.top, 30)
            Spacer()
        }
    }
    
    private var backButton: some View {
        Button {
            if !canShare {
                imageOffset = 0
            }
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: backImage)
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding()
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
    }
    
    private var displayImage: some View {
        VStack(spacing: 0) {
            if (images.count > 1) {
                multipleImages
                
            } else {
                if (!images.isEmpty) {
                    if (spotsFromCloud[index].isMultipleImages != 0) {
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
    }
    
    private var multipleImages: some View {
        TabView(selection: $selection) {
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
    
    private var enlargeImageButton: some View {
        Button {
            withAnimation {
                showingImage.toggle()
            }
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 15, weight: .regular))
                .padding(5)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
    
    private var deleteButton: some View { // if myspot
        Button {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            deleteAlert.toggle()
        } label: {
            Image(systemName: "trash.fill")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(10)
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
        .alert("Are You Sure You Want To Delete ".localized() + (spotsFromCloud[index].name) + "?".localized(), isPresented: $deleteAlert) {
            Button("Delete".localized(), role: .destructive) {
                let spotID = spotsFromCloud[index].record.recordID
                Task {
                    do {
                        try await cloudViewModel.deleteSpot(id: spotID)
                        DispatchQueue.main.async {
                            spots.forEach { i in
                                if i.dbid == spotID.recordName {
                                    i.isPublic = false
                                    CoreDataStack.shared.save()
                                    return
                                }
                            }
                            if !canShare {
                                imageOffset = 0
                            }
                            spotsFromCloud.remove(at: index)
                            presentationMode.wrappedValue.dismiss()
                        }
                    } catch {
                        DispatchQueue.main.async {
                            cloudViewModel.isErrorMessage = "Error Deleting Spot".localized()
                            cloudViewModel.isErrorMessageDetails = "Please check internet connection and try again.".localized()
                            cloudViewModel.isError.toggle()
                        }
                    }
                }
            }
        } message: {
            Text("Spot will be removed from 'Discover' tab and no longer sharable. If this spot is still in 'My Spots' tab, it will not be deleted there.".localized())
        }
    }
    
    private var downloadButton: some View {
        Button {
            withAnimation {
                showingSaveSheet = true
            }
        } label: {
            if !showSaveAlert {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 30, weight: .regular))
                    .padding(15)
                    .foregroundColor(.white)
            } else {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .background(
            Circle()
                .foregroundColor((spotInCD || isSaved) == true ? .gray : cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .shadow(color: Color.black.opacity(0.3), radius: 5)
        )
        .disabled(spotInCD || isSaved)
    }
    
    private var canShareButton: some View {
        Button {
            isShare = true
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(10)
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
    }
    
    private var expandButton: some View {
        Image(systemName: (expand ? "x.circle.fill" : "arrow.up.circle.fill"))
            .resizable()
            .frame(width: (expand ? 50 : 30), height: (expand ? 50 : 30))
            .foregroundColor(Color.secondary)
            .onTapGesture {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation {
                    expand.toggle()
                }
            }
            .padding(.top, 5)
    }
    
    private func getShareAC(id: String, name: String) -> UIActivityViewController {
        return UIActivityViewController(activityItems: ["Check out, \"".localized() + name + "\" on My Spot! ".localized(), URL(string: "myspot://" + (id)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ".localized(), URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
    }
    
    private var bottomHalf: some View {
        VStack {
            if !didCopy {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = "myspot://" + (spotsFromCloud[index].record.recordID.recordName)
                    didCopy = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Share ID".localized())
                    }
                    .padding(.horizontal)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 10)
                .padding([.leading, .trailing], 30)
            } else {
                HStack {
                    Text("Copied".localized())
                    Image(systemName: "checkmark.square.fill")
                }
                .padding(.top, 10)
                .padding([.leading, .trailing], 30)
            }
            
            if (!distance.isEmpty) {
                Text((distance) + " away".localized())
                    .foregroundColor(.gray)
                    .font(.system(size: 15, weight: .light))
                    .padding([.top, .bottom], 10)
            }
            if (!attemptToReport) {
                if !hasReported {
                    Button {
                        showingReportAlert = true
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
                }
            } else {
                ProgressView().progressViewStyle(.circular)
                    .padding([.top, .bottom], 10)
            }
        }
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            expandButton
            if (!spotsFromCloud[index].locationName.isEmpty) {
                HStack {
                    Image(systemName: (spotsFromCloud[index].customLocation != 0 ? "mappin" : "figure.wave"))
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                    Text("\(spotsFromCloud[index].locationName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 1)
                    Spacer()
                }
                .padding([.leading, .trailing], 30)
            }
            
            HStack {
                Text("\(spotsFromCloud[index].name)")
                    .font(.system(size: 45, weight: .heavy))
                Spacer()
            }
            .padding(.leading, 30)
            .padding(.trailing, 5)
            
            HStack {
                Text("By: \(spotsFromCloud[index].founder)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Spacer()
                Text(dateToShow)
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding([.leading, .trailing], 30)
            .onAppear {
                if let date = spotsFromCloud[index].dateObject {
                    let timeFormatter = DateFormatter()
                    timeFormatter.dateFormat = "MMM d, yyyy"
                    dateToShow = timeFormatter.string(from: date)
                } else {
                    dateToShow = spotsFromCloud[index].date.components(separatedBy: ";")[0]
                }
            }
            
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(spotsFromCloud[index].likes)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                    .padding(.leading, 1)
                Spacer()
            }
            .padding([.leading, .trailing], 30)
            .offset(y: 5)
            
            if (!noType) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .regular))
                                .lineLimit(2)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(.tint)
                                .cornerRadius(5)
                        }
                    }
                }
                .padding([.leading, .trailing], 30)
                .offset(y: 5)
            }
            ZStack {
                HStack(spacing: 5) {
                    Text(spotsFromCloud[index].description)
                    Spacer()
                }
                if didCopyDescription {
                    HStack {
                        Spacer()
                        Text("Copied".localized())
                            .padding(10)
                            .background(Capsule().foregroundColor(.gray))
                        Spacer()
                    }
                }
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            .onTapGesture {
                if !spotsFromCloud[index].description.isEmpty {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = spotsFromCloud[index].description
                    withAnimation {
                        didCopyDescription = true
                    }
                }
            }
            .onChange(of: didCopyDescription) { newValue in
                if newValue {
                    let _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { timer in
                        withAnimation {
                            didCopyDescription = false
                        }
                    }
                }
            }
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: spotsFromCloud[index].name, coordinate: spotsFromCloud[index].location.coordinate)])
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: spotsFromCloud[index].location.coordinate))
                routeMeTo.name = spotsFromCloud[index].name
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text(spotsFromCloud[index].name)
                }
                .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            bottomHalf
        }
        .confirmationDialog("How should this spot be reported?".localized(), isPresented: $showingReportAlert) {
            Button("Offensive".localized()) {
                let spot = spotsFromCloud[index]
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "offensive")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Inappropriate".localized()) {
                let spot = spotsFromCloud[index]
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "inappropriate")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Spam".localized()) {
                let spot = spotsFromCloud[index]
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "spam")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Dangerous".localized()) {
                let spot = spotsFromCloud[index]
                Task {
                    attemptToReport = true
                    await cloudViewModel.report(spot: spot, report: "dangerous")
                    hasReported = true
                    attemptToReport = false
                }
            }
            Button("Cancel".localized(), role: .cancel) { }
        }
        .onAppear {
            if (mapViewModel.isAuthorized) {
                calculateDistance()
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .cornerRadius(radius: 20, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.8), radius: 5)
                .mask(Rectangle().padding(.top, -20))
        )
    }
    
    private func isSpotInCoreData() -> Bool {
        var isInSpots = false
        spots.forEach { spot in
            if spot.dbid == spotsFromCloud[index].record.recordID.recordName {
                isInSpots = true
                return
            }
        }
        return isInSpots
    }
    
    private func save() async {
        let newSpot = Spot(context: moc)
        newSpot.founder = spotsFromCloud[index].founder
        newSpot.details = spotsFromCloud[index].description
        newSpot.image = images[0]
        if images.count == 3 {
            newSpot.image2 = images[1]
            newSpot.image3 = images[2]
        } else if images.count == 2 {
            newSpot.image2 = images[1]
        }
        newSpot.isShared = false
        newSpot.userId = cloudViewModel.userID
        newSpot.locationName = spotsFromCloud[index].locationName
        newSpot.name = (newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? spotsFromCloud[index].name : newName)
        newSpot.x = spotsFromCloud[index].location.coordinate.latitude
        newSpot.y = spotsFromCloud[index].location.coordinate.longitude
        newSpot.isPublic = false
        if spotsFromCloud[index].userID != cloudViewModel.userID {
            newSpot.fromDB = true
        } else {
            newSpot.fromDB = false
        }
        newSpot.tags = spotsFromCloud[index].type
        newSpot.date = spotsFromCloud[index].date
        if let dateObject = spotsFromCloud[index].dateObject {
            newSpot.dateObject = dateObject
        } else {
            newSpot.dateObject = nil
        }
        if spotsFromCloud[index].customLocation == 1 {
            newSpot.wasThere = false
        } else {
            newSpot.wasThere = true
        }
        newSpot.id = UUID()
        newSpot.dbid = spotsFromCloud[index].record.recordID.recordName
        CoreDataStack.shared.save()
        let hashcode = newSpot.name ?? "" + "\(newSpot.x)\(newSpot.y)"
        await updateAppGroup(hashcode: hashcode, image: newSpot.image, x: newSpot.x, y: newSpot.y, name: newSpot.name ?? "", locatioName: newSpot.name ?? "")
        isSaved = true
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let distanceInMeters = userLocation.distance(from: spotsFromCloud[index].location)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            distance = String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            distance = String(format: "%.1f", distanceDouble) + " mi"
        }
        
    }
    
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
    
    private func updateAppGroup(hashcode: String, image: UIImage?, x: Double, y: Double, name: String, locatioName: String) async {
        let userDefaults = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")
        guard var xArr: [Double] = userDefaults?.object(forKey: "spotXs") as? [Double] else { return }
        guard var yArr: [Double] = userDefaults?.object(forKey: "spotYs") as? [Double] else { return }
        guard var nameArr: [String] = userDefaults?.object(forKey: "spotNames") as? [String] else { return }
        guard var locationNameArr: [String] = userDefaults?.object(forKey: "spotLocationName") as? [String] else { return }
        guard var imgArr: [Data] = userDefaults?.object(forKey: "spotImgs") as? [Data] else { return }
        guard let data = image?.jpegData(compressionQuality: 0.5) else { return }
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
}