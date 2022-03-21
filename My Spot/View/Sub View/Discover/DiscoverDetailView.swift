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

struct DiscoverDetailView: View {
    
    var index: Int
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.managedObjectContext) var moc
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    let canShare: Bool
    @State private var deletedSpot: [Spot] = []
    @State private var backImage = "chevron.left"
    @State private var mySpot = false
    @State private var distance: String = ""
    @State private var message = ""
    @State private var deleteAlert = false
    @State private var showingMailSheet = false
    @State private var isSaving = false
    @State private var likeButton = "heart"
    @State private var newName = ""
    @State private var isSaved: Bool = false
    @State private var tags: [String] = []
    @State private var image: UIImage?
    @State private var showingImage = false
    @State private var showingSaveSheet = false
    @State private var didLike = false
    @State private var noType = false
    @State private var spotInCD: [Spot] = []
    @FocusState private var nameIsFocused: Bool
    @State private var landscapeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            if(cloudViewModel.spots.count > 0 && cloudViewModel.spots.count >= index + 1) {
                ZStack {
                    VStack {
                        Image(uiImage: (image ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
                            .resizable()
                            .scaledToFit()
                        Spacer()
                    }
                    detailSheet
                        .if(landscapeOffset != 0, transform: { view in
                            view.offset(y: landscapeOffset + 50)
                        })
                    HStack {
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
                        .offset(x: 20, y: -80 + landscapeOffset)
                        Spacer()
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
                        .offset(x: -20, y: -60 + landscapeOffset)
                    }
                    HStack {
                        VStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: backImage)
                                    .foregroundColor(.white)
                                    .font(.system(size: 30, weight: .regular))
                                    .padding(15)
                                    .shadow(color: .black, radius: 5)
                            }
                            .offset(y: 30)
                            Spacer()
                        }
                        Spacer()
                        VStack {
                            HStack(spacing: -15) {
                                Spacer()
                                if (mySpot) {
                                    Button {
                                        deleteAlert.toggle()
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 30, weight: .regular))
                                            .padding(15)
                                            .shadow(color: .black, radius: 5)
                                    }
                                    .offset(y: 30)
                                    .alert("Are you sure you want to delete \(cloudViewModel.spots[index].name)?", isPresented: $deleteAlert) {
                                        Button("Delete", role: .destructive) {
                                            spots.forEach { i in
                                                if i.dbid == cloudViewModel.spots[index].record.recordID.recordName {
                                                    i.isPublic = false
                                                    try? moc.save()
                                                }
                                            }
                                            cloudViewModel.deleteSpot(id: cloudViewModel.spots[index].record.recordID)
                                            cloudViewModel.spots.remove(at: index)
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }
                                if (canShare) {
                                    Button {
                                        cloudViewModel.shareSheet(index: index)
                                    } label: {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundColor(.white)
                                            .font(.system(size: 30, weight: .regular))
                                            .padding(15)
                                            .shadow(color: .black, radius: 5)
                                    }
                                    .offset(y: 30)
                                }
                                Button {
                                    let spot = cloudViewModel.spots[index]
                                    if (likeButton == "heart") {
                                        Task {
                                            didLike = await cloudViewModel.likeSpot(spot: spot, like: true)
                                            if (didLike) {
                                                DispatchQueue.main.async {
                                                    let newLike = Likes(context: moc)
                                                    newLike.likedId = String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name
                                                    try? moc.save()
                                                    likeButton = "heart.fill"
                                                    cloudViewModel.spots[index].likes += 1
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
                                                        if (i.likedId == String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name) {
                                                            moc.delete(i)
                                                            try? moc.save()
                                                            break
                                                        }
                                                    }
                                                    likeButton = "heart"
                                                    cloudViewModel.spots[index].likes -= 1
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
                                            .padding(15)
                                            .shadow(color: .black, radius: 5)
                                    } else {
                                        ProgressView()
                                            .padding(15)
                                    }
                                }
                                .offset(y: 30)
                            }
                            Spacer()
                        }
                    }
                    if (showingImage) {
                        ImagePopUp(showingImage: $showingImage, image: (image ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
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
                    mySpot = cloudViewModel.isMySpot(user: cloudViewModel.spots[index].userID)
                    tags = cloudViewModel.spots[index].type.components(separatedBy: ", ")
                    let url = cloudViewModel.spots[index].imageURL
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        self.image = image
                        if (image.size.height < image.size.width) {
                            landscapeOffset = -(60 * UIScreen.screenWidth)/375 - 50
                        }
                    }
                    isSaving = false
                    newName = ""
                    var didlike = false
                    for i in likedIds {
                        if i.likedId == String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name {
                            didlike = true
                            break
                        }
                    }
                    if (didlike) {
                        likeButton = "heart.fill"
                    }
                    message = "The public spot with id: " + cloudViewModel.spots[index].id + ", has the following issue(s):\n"
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
            noType = cloudViewModel.spots[index].type.isEmpty
            spotInCD = isSpotInCoreData()
            if (canShare) {
                backImage = "chevron.left"
            } else {
                backImage = "chevron.down"
            }
        }
    }
    
    private var detailSheet: some View {
        ScrollView(showsIndicators: false) {
            
            if (!cloudViewModel.spots[index].locationName.isEmpty) {
                HStack {
                    Image(systemName: "mappin")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                    Text("\(cloudViewModel.spots[index].locationName)")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color.gray)
                        .padding(.leading, 1)
                    Spacer()
                }
                .padding([.top, .leading, .trailing], 30)
            }
            
            
            HStack {
                Text("\(cloudViewModel.spots[index].name)")
                    .font(.system(size: 45, weight: .heavy))
                Spacer()
            }
            .padding(.leading, 30)
            .padding(.trailing, 5)
            
            HStack {
                Text("By: \(cloudViewModel.spots[index].founder)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Spacer()
                Text("\(cloudViewModel.spots[index].date)")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
            }
            .padding([.leading, .trailing], 30)
            
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(Color.gray)
                Text("\(cloudViewModel.spots[index].likes)")
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
                Text(cloudViewModel.spots[index].description)
                Spacer()
            }
            .padding(.top, 10)
            .padding([.leading, .trailing], 30)
            
            ViewSingleSpotOnMap(singlePin: [SinglePin(name: cloudViewModel.spots[index].name, coordinate: cloudViewModel.spots[index].location.coordinate)])
                .aspectRatio(contentMode: .fit)
                .cornerRadius(15)
                .padding([.leading, .trailing], 30)
            
            Button {
                let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.spots[index].location.coordinate))
                routeMeTo.name = cloudViewModel.spots[index].name
                routeMeTo.openInMaps(launchOptions: nil)
            } label: {
                Text("Take Me To \(cloudViewModel.spots[index].name)")
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
            .padding(.top, 20)
            .padding(.bottom, (100 * UIScreen.screenWidth)/375)
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
        .frame(height: (500 * UIScreen.screenWidth)/375 - landscapeOffset)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black, radius: 5)
        )
        .offset(y: (200 * UIScreen.screenWidth)/375)
    }
    
    private func isSpotInCoreData() -> [Spot] {
        let fetchRequest: NSFetchRequest<Spot> = Spot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dbid == %@", cloudViewModel.spots[index].record.recordID.recordName as CVarArg)
        do {
            let spotsFound: [Spot] = try moc.fetch(fetchRequest)
            return spotsFound
        } catch {
            return []
        }
    }
    
    private func save() {
        let newSpot = Spot(context: moc)
        newSpot.founder = cloudViewModel.spots[index].founder
        newSpot.details = cloudViewModel.spots[index].description
        newSpot.image = image
        newSpot.locationName = cloudViewModel.spots[index].locationName
        newSpot.name = newName
        newSpot.x = cloudViewModel.spots[index].location.coordinate.latitude
        newSpot.y = cloudViewModel.spots[index].location.coordinate.longitude
        newSpot.isPublic = false
        newSpot.tags = cloudViewModel.spots[index].type
        newSpot.date = cloudViewModel.spots[index].date
        newSpot.id = UUID()
        newSpot.dbid = cloudViewModel.spots[index].record.recordID.recordName
        try? moc.save()
        isSaved = true
    }
    
    private func calculateDistance() {
        let userLocation = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
        let distanceInMeters = userLocation.distance(from: cloudViewModel.spots[index].location)
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
