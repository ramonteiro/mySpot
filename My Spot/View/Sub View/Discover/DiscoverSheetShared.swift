//
//  DiscoverDetailView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DiscoverDetailView:
 navigation link for each spot from db item in list in root view
 */

import SwiftUI
import Combine
import MapKit
import CoreData

struct DiscoverSheetShared: View {
    
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var deletedSpot: [Spot] = []
    @State private var mySpot = false
    @State private var distance: String = ""
    @State private var message = ""
    @State private var deleteAlert = false
    @State private var showingMailSheet = false
    @State private var selection = 0
    @State private var isSaving = false
    @State private var likeButton = "heart"
    @State private var newName = ""
    @State private var isSaved: Bool = false
    @State private var tags: [String] = []
    @State private var images: [UIImage] = []
    @State private var showingImage = false
    @State private var showingSaveSheet = false
    @State private var didLike = false
    @State private var noType = false
    @State private var spotInCD: [Spot] = []
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        ZStack {
            if(cloudViewModel.shared.count == 1) {
                ZStack {
                    displayImage
                    topButtonRow
                    middleButtonRow
                    if (showingImage) {
                        ImagePopUp(showingImage: $showingImage, image: images[selection])
                            .transition(.scale)
                    }
                }
                .ignoresSafeArea(.all, edges: .top)
                .onChange(of: tabController.discoverPopToRoot) { _ in
                    presentationMode.wrappedValue.dismiss()
                }
                .onChange(of: isSaving) { newValue in
                    if newValue {
                        save()
                    }
                }
                .onAppear {
                    mySpot = cloudViewModel.isMySpot(user: cloudViewModel.shared[0].userID)
                    tags = cloudViewModel.shared[0].type.components(separatedBy: ", ")
                    
                    // check for images
                    let url = cloudViewModel.shared[0].imageURL
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        self.images.append(image)
                    }
                    let url2 = cloudViewModel.shared[0].image2URL
                    let url3 = cloudViewModel.shared[0].image3URL
                    if url3.absoluteString != "none" {
                        if let data = try? Data(contentsOf: url2), let image = UIImage(data: data) {
                            self.images.append(image)
                        }
                        if let data = try? Data(contentsOf: url3), let image = UIImage(data: data) {
                            self.images.append(image)
                        }
                    } else if url2.absoluteString != "none" {
                        if let data = try? Data(contentsOf: url2), let image = UIImage(data: data) {
                            self.images.append(image)
                        }
                    }
                    
                    
                    isSaving = false
                    newName = ""
                    var didlike = false
                    for i in likedIds {
                        if i.likedId == String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name {
                            didlike = true
                            break
                        }
                    }
                    if (didlike) {
                        likeButton = "heart.fill"
                    }
                    message = "The public spot with id: " + cloudViewModel.shared[0].id + ", has the following issue(s):\n"
                    cloudViewModel.canRefresh = false
                }
            }
        }
        .popup(isPresented: $showingSaveSheet) {
            BottomPopupView {
                NamePopupView(isPresented: $showingSaveSheet, text: $newName, saved: $isSaving)
            }
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            noType = cloudViewModel.shared[0].type.isEmpty
            spotInCD = isSpotInCoreData()
        }
    }
    
    private var middleButtonRow: some View {
        VStack {
            Spacer()
                .ignoresSafeArea()
                .frame(height: UIScreen.screenWidth)
            HStack {
                enlargeImageButton
                    .padding()
                    .offset(y: -30)
                Spacer()
                downloadButton
                    .padding()
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
                
                displayLikeButton
            }
            .padding(.top, 30)
            Spacer()
        }
    }
    
    private var backButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "chevron.down")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding()
                .shadow(color: .black, radius: 5)
        }
    }
    
    private var displayImage: some View {
        VStack(spacing: 0) {
            if (images.count > 1) {
                multipleImages
            } else {
                if (!images.isEmpty) {
                    Image(uiImage: images[0])
                        .resizable()
                        .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                        .scaledToFit()
                        .ignoresSafeArea()
                } else {
                    Image(uiImage: defaultImages.errorImage!)
                        .resizable()
                        .frame(width: UIScreen.screenWidth, height: UIScreen.screenWidth)
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            }
            detailSheet
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
                .foregroundColor(.white)
        }
        .background(.ultraThinMaterial)
        .clipShape(Circle())
    }
    
    private var deleteButton: some View { // if myspot
        Button {
            deleteAlert.toggle()
        } label: {
            Image(systemName: "trash.fill")
                .foregroundColor(.white)
                .font(.system(size: 30, weight: .regular))
                .padding(10)
                .shadow(color: .black, radius: 5)
        }
        .alert("Are you sure you want to delete \(cloudViewModel.shared[0].name)?", isPresented: $deleteAlert) {
            Button("Delete", role: .destructive) {
                spots.forEach { i in
                    if i.dbid == cloudViewModel.shared[0].record.recordID.recordName {
                        i.isPublic = false
                        try? moc.save()
                    }
                }
                cloudViewModel.deleteSpot(id: cloudViewModel.shared[0].record.recordID)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private var downloadButton: some View {
        Button {
            withAnimation {
                showingSaveSheet = true
            }
        } label: {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 30, weight: .regular))
                .padding(15)
                .foregroundColor(.white)
        }
        .background(
            Circle()
                .foregroundColor(.accentColor)
                .shadow(color: .black, radius: 5)
        )
        .disabled(spotInCD.count != 0 || isSaved)
    }
    
    private var displayLikeButton: some View {
        Button {
            let spot = cloudViewModel.shared[0]
            if (likeButton == "heart") {
                Task {
                    didLike = await cloudViewModel.likeSpot(spot: spot, like: true)
                    if (didLike) {
                        DispatchQueue.main.async {
                            let newLike = Likes(context: moc)
                            newLike.likedId = String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name
                            try? moc.save()
                            likeButton = "heart.fill"
                            cloudViewModel.shared[0].likes += 1
                            didLike = false
                        }
                    }
                }
            } else {
                Task {
                    didLike = await cloudViewModel.likeSpot(spot: spot, like: false)
                    if (didLike) {
                        DispatchQueue.main.async {
                            for i in likedIds {
                                if (i.likedId == String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name) {
                                    moc.delete(i)
                                    try? moc.save()
                                    break
                                }
                            }
                            likeButton = "heart"
                            cloudViewModel.shared[0].likes -= 1
                            didLike = false
                        }
                    }
                }
            }
        } label: {
            if (!didLike) {
                Image(systemName: likeButton)
                    .foregroundColor(.white)
                    .font(.system(size: 30, weight: .regular))
                    .padding(10)
                    .shadow(color: .black, radius: 5)
            } else {
                ProgressView()
                    .padding(10)
            }
        }
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            
            if (!cloudViewModel.shared[0].locationName.isEmpty) {
                HStack {
                    Image(systemName: "mappin")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                    Text("\(cloudViewModel.shared[0].locationName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 1)
                    Spacer()
                }
                .padding([.top, .leading, .trailing], 30)
            }
            
            
            HStack {
                Text("\(cloudViewModel.shared[0].name)")
                    .font(.system(size: 45, weight: .heavy))
                Spacer()
            }
            .padding(.leading, 30)
            .padding(.trailing, 5)
            
            HStack {
                Text("By: \(cloudViewModel.shared[0].founder)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Spacer()
                Text("\(cloudViewModel.shared[0].date)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding([.leading, .trailing], 30)
            
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(cloudViewModel.shared[0].likes)")
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
            HStack(spacing: 5) {
                Text(cloudViewModel.shared[0].description)
                Spacer()
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: cloudViewModel.shared[0].name, coordinate: cloudViewModel.shared[0].location.coordinate)])
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.shared[0].location.coordinate))
                routeMeTo.name = cloudViewModel.shared[0].name
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                Text("Take Me To \(cloudViewModel.shared[0].name)")
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
            
            Button {
                showingMailSheet = true
            } label: {
                HStack {
                    Text("Report Spot")
                    Image(systemName: "exclamationmark.triangle.fill")
                }
            }
            .padding([.top, .bottom], 20)
            .sheet(isPresented: $showingMailSheet) {
                MailView(message: $message) { returnedMail in
                    print(returnedMail)
                }
            }
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
                .shadow(color: .black, radius: 5)
        )
    }
    
    private func isSpotInCoreData() -> [Spot] {
        let fetchRequest: NSFetchRequest<Spot> = Spot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dbid == %@", cloudViewModel.shared[0].record.recordID.recordName as CVarArg)
        do {
            let spotsFound: [Spot] = try moc.fetch(fetchRequest)
            return spotsFound
        } catch {
            return []
        }
    }
    
    private func save() {
        let newSpot = Spot(context: moc)
        newSpot.founder = cloudViewModel.shared[0].founder
        newSpot.details = cloudViewModel.shared[0].description
        newSpot.image = images[0]
        if images.count == 3 {
            newSpot.image2 = images[1]
            newSpot.image3 = images[2]
        } else if images.count == 2 {
            newSpot.image2 = images[1]
        }
        newSpot.locationName = cloudViewModel.shared[0].locationName
        newSpot.name = newName
        newSpot.x = cloudViewModel.shared[0].location.coordinate.latitude
        newSpot.y = cloudViewModel.shared[0].location.coordinate.longitude
        newSpot.isPublic = false
        newSpot.tags = cloudViewModel.shared[0].type
        newSpot.date = cloudViewModel.shared[0].date
        newSpot.id = UUID()
        newSpot.dbid = cloudViewModel.shared[0].record.recordID.recordName
        try? moc.save()
        isSaved = true
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let distanceInMeters = userLocation.distance(from: cloudViewModel.shared[0].location)
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
