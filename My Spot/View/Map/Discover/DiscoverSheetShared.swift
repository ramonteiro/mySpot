//
//  DiscoverSheetShared.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//


import SwiftUI
import Combine
import MapKit
import CoreData

struct DiscoverSheetShared: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var message = ""
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
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        ZStack {
            if(cloudViewModel.shared.count == 1) {
                ZStack {
                    VStack {
                        Image(uiImage: (image ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
                            .resizable()
                            .scaledToFit()
                            .offset(y: -100)
                        Spacer()
                    }
                    detailSheet
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
                        .offset(x: 20, y: -80)
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
                        .disabled(isSpotInCoreData().count != 0 || isSaved)
                        .offset(x: -20, y: -60)
                    }
                    HStack {
                        VStack {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Image(systemName: "arrow.left")
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
                                        .padding(15)
                                        .shadow(color: .black, radius: 5)
                                } else {
                                    ProgressView()
                                        .padding(15)
                                }
                            }
                            .offset(x: -10, y: 30)
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
                    tags = cloudViewModel.shared[0].type.components(separatedBy: ", ")
                    let url = cloudViewModel.shared[0].imageURL
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        self.image = image
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
            
            if (!cloudViewModel.shared[0].type.isEmpty) {
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
        .frame(maxWidth: .infinity)
        .frame(height: (500 * UIScreen.screenWidth)/375)
        .background(
            RoundedRectangle(cornerRadius: 40)
                .foregroundColor(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black, radius: 5)
        )
        .offset(y: (200 * UIScreen.screenWidth)/375)
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
        newSpot.image = image
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
}
