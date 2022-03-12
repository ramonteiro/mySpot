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
    
    var spot: SpotFromCloud
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var nameInTitle = ""
    @State private var isSaving = false
    @State private var likeButton = "hand.thumbsup"
    @State private var newName = ""
    @State private var likes = 0
    @State private var imageLoaded: Bool = false
    @State private var isSaved: Bool = false
    @State private var didLikeNow = false
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        Form {
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .onAppear {
                        imageLoaded = true
                    }
            } else {
                HStack {
                    Spacer()
                    ProgressView("Loading Image")
                    Spacer()
                }
                .onAppear {
                    imageLoaded = false
                }
            }
            Text("Found by: \(spot.founder)\nOn \(spot.date)\nTag: \(spot.type)").font(.subheadline).foregroundColor(.gray)
            Section(header: Text("Description")) {
                Text(spot.description)
            }
            Section(header: Text("Location")) {
                ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name, coordinate: spot.location.coordinate)])
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
                Button("Take Me To \(spot.name)") {
                    let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.location.coordinate.latitude, longitude: spot.location.coordinate.longitude)))
                    routeMeTo.name = spot.name
                    routeMeTo.openInMaps(launchOptions: nil)
                }
                .accentColor(.blue)
            }
            .accentColor(.red)
            if (isSpotInCoreData().count == 0 && !isSaved) {
                Section(header: Text("Save To My Spots")) {
                    if (!isSaving) {
                        Button("Save") {
                            isSaving = true
                        }
                        .disabled(!imageLoaded)
                        .accentColor(.blue)
                    }
                    if (isSaving) {
                        TextField("Enter Spot Name", text: $newName)
                            .focused($nameIsFocused)
                            .onReceive(Just(newName)) { _ in
                                if (newName.count > MaxCharLength.names) {
                                    newName = String(newName.prefix(MaxCharLength.names))
                                }
                            }
                        Button("Save") {
                            save()
                            isSaved = true
                        }
                        .accentColor(.blue)
                        .disabled(newName == "")
                    }
                }
            }
        }
        .onAppear() {
            nameInTitle = spot.name
            isSaving = false
            imageLoaded = false
            newName = ""
            likes = spot.likes
            var didlike = false
            print("\(likedIds.count)")
            for i in likedIds {
                print(i.likedId ?? "none?")
            }
            for i in likedIds {
                if i.likedId == String(spot.location.coordinate.latitude + spot.location.coordinate.longitude) + spot.name {
                    didlike = true
                    break
                }
            }
            if (didlike) {
                likeButton = "hand.thumbsup.fill"
            }
        }
        .navigationTitle(nameInTitle)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Done") {
                    nameIsFocused = false
                }
                .accentColor(.blue)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Text("\(likes)")
                    .foregroundColor(.red)
                Button(action: {
                    if (!didLikeNow) {
                        if (likeButton == "hand.thumbsup") {
                            let newLike = Likes(context: moc)
                            newLike.likedId = String(spot.location.coordinate.latitude + spot.location.coordinate.longitude) + spot.name
                            try? moc.save()
                            didLikeNow = true
                            likeButton = "hand.thumbsup.fill"
                            cloudViewModel.likeSpot(spot: spot, like: true)
                            likes += 1
                        } else {
                            for i in likedIds {
                                if (i.likedId == String(spot.location.coordinate.latitude + spot.location.coordinate.longitude) + spot.name) {
                                    moc.delete(i)
                                    try? moc.save()
                                    break
                                }
                            }
                            didLikeNow = true
                            likeButton = "hand.thumbsup"
                            cloudViewModel.likeSpot(spot: spot, like: false)
                            likes -= 1
                        }
                    }
                }, label: {
                    Image(systemName: likeButton)
                })
                .accentColor(.red)
                .padding()
            }
        }
        .onChange(of: tabController.discoverPopToRoot) { _ in
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func isSpotInCoreData() -> [Spot] {
        let fetchRequest: NSFetchRequest<Spot> = Spot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dbid == %@", spot.record.recordID.recordName as CVarArg)
        do {
            let spotsFound: [Spot] = try moc.fetch(fetchRequest)
            return spotsFound
        } catch {
            return []
        }
    }
    
    private func save() {
        let url = spot.imageURL
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            let newSpot = Spot(context: moc)
            newSpot.founder = spot.founder
            newSpot.details = spot.description
            newSpot.image = image
            newSpot.name = newName
            newSpot.x = spot.location.coordinate.latitude
            newSpot.y = spot.location.coordinate.longitude
            newSpot.isPublic = false
            newSpot.type = spot.type
            newSpot.date = spot.date
            newSpot.id = UUID()
            newSpot.dbid = spot.record.recordID.recordName
            try? moc.save()
        }
    }
}
