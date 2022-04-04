//
//  DetailView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DetailView:
 navigation link for each spot from core data item in list in root view
 */

import SwiftUI
import MapKit

struct DetailView: View {
    
    var canShare: Bool
    var fromPlaylist: Bool
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @FetchRequest(sortDescriptors: [], animation: .default) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var spot:Spot
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var tabController: TabController
    @State private var showingEditSheet = false
    @State private var backImage = "chevron.left"
    @State private var scope:String = "Private"
    @State private var tags: [String] = []
    @State private var showingImage = false
    @State private var deleteAlert = false
    @State private var distance: String = ""
    @State private var exists = true
    @State private var imageOffset: CGFloat = -50
    @State private var selection = 0
    @State private var images: [UIImage] = []
    @State private var showingCannotSavePublicAlert = false
    @State private var pu = false
    private var idiom : UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    
    var body: some View {
        ZStack {
            if (exists) {
                displaySpot
                    .alert("Unable To Save Spot", isPresented: $pu) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Failed to upload spot. Spot is now set to private, please try again later and check internet connection.")
                    }
                    .onChange(of: tabController.playlistPopToRoot) { _ in
                        if (fromPlaylist) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .onChange(of: tabController.spotPopToRoot) { _ in
                        if (!fromPlaylist) {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
            }
        }
        .onAppear {
            exists = checkExists()
        }
    }
    
    private func checkExists() -> Bool {
        guard let _ = spot.name else {return false}
        guard let _ = spot.locationName else {return false}
        guard let _ = spot.date else {return false}
        guard let _ = spot.details else {return false}
        guard let _ = spot.founder else {return false}
        return true
    }
    
    private var displaySpot: some View {
        ZStack {
            displayImage
                .offset(y: imageOffset)
            VStack {
                Spacer()
                    .frame(height: (idiom == .pad ? UIScreen.screenHeight/2 - 65 : UIScreen.screenWidth - 65))
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
        .onAppear {
            // check for images
            images.append(spot.image ?? defaultImages.errorImage!)
            if let _ = spot.image3 {
                images.append(spot.image2 ?? defaultImages.errorImage!)
                images.append(spot.image3 ?? defaultImages.errorImage!)
            } else if let _ = spot.image2 {
                images.append(spot.image2 ?? defaultImages.errorImage!)
            }
            
            tags = spot.tags?.components(separatedBy: ", ") ?? []
            if (spot.isPublic) {
                scope = "Public"
            } else {
                scope = "Private"
            }
            if (canShare) {
                backImage = "chevron.left"
            } else {
                backImage = "chevron.down"
            }
        }
        .navigationBarHidden(true)
    }
    
    private var displayImage: some View {
        VStack(spacing: 0) {
            if (images.count > 1) {
                multipleImages
            } else {
                if (!images.isEmpty) {
                    Image(uiImage: images[0])
                        .resizable()
                        .frame(width: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth), height: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth))
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    Image(uiImage: defaultImages.errorImage!)
                        .resizable()
                        .frame(width: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth), height: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth))
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            }
            Spacer()
        }
    }
    
    private var topButtonRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                backButtonView
                Spacer()
                deleteButton
                if (canShare && spot.isPublic) {
                    shareButton
                }
            }
            .padding(.top, 30)
            Spacer()
        }
    }
    
    private var middleButtonRow: some View {
        VStack {
            Spacer()
                .ignoresSafeArea()
                .frame(height: UIScreen.screenWidth)
                .if(idiom == .pad) { view in
                    view.frame(maxWidth: UIScreen.screenHeight/2, maxHeight: UIScreen.screenHeight/2)
                }
            HStack {
                enLargeButton
                    .padding()
                    .offset(y: -30)
                Spacer()
                editButton
                    .padding()
            }
            .offset(y: -60)
            Spacer()
        }
    }
    
    private var multipleImages: some View {
        TabView(selection: $selection) {
            ForEach(images.indices, id: \.self) { index in
                Image(uiImage: images[index]).resizable()
                    .frame(width: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth), height: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth))
                    .scaledToFit()
                    .ignoresSafeArea()
                    .tag(index)
            }
        }
        .frame(width: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth), height: (idiom == .pad ? UIScreen.screenHeight/2 : UIScreen.screenWidth))
        .tabViewStyle(.page)
    }
    
    private var enLargeButton: some View {
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
    
    private var shareButton: some View {
        Button {
            cloudViewModel.shareSheetFromLocal(id: spot.dbid ?? "", name: spot.name ?? "")
        } label: {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(15)
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
    }
    
    private var deleteButton: some View {
        Button {
            deleteAlert.toggle()
        } label: {
            Image(systemName: "trash.fill")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(10)
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
        .alert("Are you sure you want to delete \(spot.name ?? "").", isPresented: $deleteAlert) {
            Button("Delete", role: .destructive) {
                if let i = spots.firstIndex(of: spot) {
                    moc.delete(spots[i])
                    do {
                        try moc.save()
                        if !canShare {
                            imageOffset = 0
                        }
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        print("couldnt save")
                    }
                    
                }
            }
        } message: {
            Text("Spot will be removed from 'My Spots' tab. If this spot is still in 'Discover' tab, it will not be deleted there.")
        }

    }
    
    private var backButtonView: some View {
        Button {
            if !canShare {
                imageOffset = 0
            }
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: backImage)
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(15)
                .shadow(color: Color.black.opacity(0.5), radius: 5)
        }
    }
    
    private var editButton: some View {
        Button {
            showingEditSheet = true
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 30, weight: .regular))
                .padding(15)
                .foregroundColor(.white)
        }
        .background(
            Circle()
                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .shadow(color: Color.black.opacity(0.3), radius: 5)
        )
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            if showingCannotSavePublicAlert {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                pu.toggle()
                showingCannotSavePublicAlert = false
            }
        }) {
            SpotEditSheet(spot: spot, showingCannotSavePublicAlert: $showingCannotSavePublicAlert)
        }
        .disabled(spot.isPublic && !cloudViewModel.isSignedInToiCloud)
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            
            if (!(spot.locationName?.isEmpty ?? true)) {
                HStack {
                    Image(systemName: "mappin")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                    Text("\(spot.locationName ?? "")")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 1)
                    Spacer()
                }
                .padding([.top, .leading, .trailing], 30)
            }
            
            
            HStack {
                Text("\(spot.name ?? "")")
                    .font(.system(size: 45, weight: .heavy))
                Spacer()
            }
            .padding(.leading, 30)
            .padding(.trailing, 5)
            
            HStack {
                Text("By: \(spot.founder ?? "")")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Spacer()
                Text("\(spot.date?.components(separatedBy: ";")[0] ?? "")")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding([.leading, .trailing], 30)
            
            if (!(spot.tags?.isEmpty ?? true)) {
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
            HStack(spacing: 5) {
                Text(spot.details ?? "")
                Spacer()
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name ?? "", coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))])
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                routeMeTo.name = spot.name ?? "Spot"
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                Text("Take Me To \(spot.name ?? "")")
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            if (!distance.isEmpty) {
                Text("\(distance) away")
                    .foregroundColor(.gray)
                    .font(.system(size: 15, weight: .light))
                    .padding(.bottom, 1)
            }
            
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(scope)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                    .onChange(of: spot.isPublic) { newValue in
                        if (newValue) {
                            scope = "Public"
                        } else {
                            scope = "Private"
                        }
                    }
                if (spot.isPublic && spot.likes >= 0) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                    Text("\(Int(spot.likes))")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                }
            }
            .padding(.bottom, 20)
            .onAppear {
                if spot.isPublic {
                    Task {
                        do {
                            let l = try await cloudViewModel.getLikes(idString: spot.dbid ?? "")
                            if let l = l {
                                spot.likes = Double(l)
                            } else {
                                spot.likes = -1
                            }
                        } catch {
                            spot.likes = -1
                        }
                    }
                }
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
        .onAppear {
            if (mapViewModel.isAuthorized) {
                calculateDistance()
            }
        }
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let spotLocation = CLLocation(latitude: spot.x, longitude: spot.y)
        let distanceInMeters = userLocation.distance(from: spotLocation)
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
}
