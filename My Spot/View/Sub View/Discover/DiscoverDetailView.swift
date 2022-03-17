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
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var tabController: TabController
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var message = ""
    @State private var showingMailSheet = false
    @State private var nameInTitle = ""
    @State private var isSaving = false
    @State private var likeButton = "hand.thumbsup"
    @State private var newName = ""
    @State private var imageLoaded: Bool = false
    @State private var isSaved: Bool = false
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        Form {
            if let url = cloudViewModel.spots[index].imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
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
            Text("Found by: \(cloudViewModel.spots[index].founder)\nOn \(cloudViewModel.spots[index].date)\nTag: \(cloudViewModel.spots[index].type)").font(.subheadline).foregroundColor(.gray)
            Section(header: Text("Description")) {
                Text(cloudViewModel.spots[index].description)
            }
            Section(header: Text("Location")) {
                ViewSingleSpotOnMap(singlePin: [SinglePin(name: cloudViewModel.spots[index].name, coordinate: cloudViewModel.spots[index].location.coordinate)])
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
                Button("Take Me To \(cloudViewModel.spots[index].name)") {
                    let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: cloudViewModel.spots[index].location.coordinate.latitude, longitude: cloudViewModel.spots[index].location.coordinate.longitude)))
                    routeMeTo.name = cloudViewModel.spots[index].name
                    routeMeTo.openInMaps(launchOptions: nil)
                }
                .tint(.blue)
            }
            Section(header: Text("report")) {
                Button("Report") {
                    showingMailSheet = true
                }
                .disabled(!MailView.canSendMail)
                .sheet(isPresented: $showingMailSheet) {
                    MailView(message: $message) { result in
                        print(result)
                    }
                }
            }
            if (isSpotInCoreData().count == 0 && !isSaved) {
                Section(header: Text("Save To My Spots")) {
                    if (!isSaving) {
                        Button("Save") {
                            withAnimation {
                                isSaving = true
                            }
                        }
                        .disabled(!imageLoaded)
                        .tint(.blue)
                    }
                    if (isSaving) {
                        TextField("Enter Spot Name", text: $newName)
                            .focused($nameIsFocused)
                            .submitLabel(.done)
                            .onReceive(Just(newName)) { _ in
                                if (newName.count > MaxCharLength.names) {
                                    newName = String(newName.prefix(MaxCharLength.names))
                                }
                            }
                            .onSubmit {
                                save()
                                isSaved = true
                            }
                        Button("Save") {
                            save()
                            isSaved = true
                        }
                        .accentColor(.blue)
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .onAppear() {
            nameInTitle = cloudViewModel.spots[index].name
            isSaving = false
            imageLoaded = false
            newName = ""
            var didlike = false
            for i in likedIds {
                if i.likedId == String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name {
                    didlike = true
                    break
                }
            }
            if (didlike) {
                likeButton = "hand.thumbsup.fill"
            }
            message = "The public spot with id: " + cloudViewModel.spots[index].id + ", has the following issue(s):\n"
            cloudViewModel.canRefresh = false
        }
        .navigationTitle(nameInTitle)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        nameIsFocused = false
                    }
                    .tint(.blue)
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Text("\(cloudViewModel.spots[index].likes)")
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .offset(x: 26)
                Button(action: {
                    if (likeButton == "hand.thumbsup") {
                        let newLike = Likes(context: moc)
                        newLike.likedId = String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name
                        try? moc.save()
                        likeButton = "hand.thumbsup.fill"
                        cloudViewModel.likeSpot(spot: cloudViewModel.spots[index], like: true)
                        cloudViewModel.spots[index].likes += 1
                    } else {
                        for i in likedIds {
                            if (i.likedId == String(cloudViewModel.spots[index].location.coordinate.latitude + cloudViewModel.spots[index].location.coordinate.longitude) + cloudViewModel.spots[index].name) {
                                moc.delete(i)
                                try? moc.save()
                                break
                            }
                        }
                        likeButton = "hand.thumbsup"
                        cloudViewModel.likeSpot(spot: cloudViewModel.spots[index], like: false)
                        cloudViewModel.spots[index].likes -= 1
                    }
                }, label: {
                    Image(systemName: likeButton)
                })
                .padding()
                Button {
                    cloudViewModel.shareSheet(index: index)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

            }
        }
        .onChange(of: tabController.discoverPopToRoot) { _ in
            presentationMode.wrappedValue.dismiss()
        }
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
        let url = cloudViewModel.spots[index].imageURL
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            let newSpot = Spot(context: moc)
            newSpot.founder = cloudViewModel.spots[index].founder
            newSpot.details = cloudViewModel.spots[index].description
            newSpot.image = image
            newSpot.name = newName
            newSpot.x = cloudViewModel.spots[index].location.coordinate.latitude
            newSpot.y = cloudViewModel.spots[index].location.coordinate.longitude
            newSpot.isPublic = false
            newSpot.tags = cloudViewModel.spots[index].type
            newSpot.date = cloudViewModel.spots[index].date
            newSpot.id = UUID()
            newSpot.dbid = cloudViewModel.spots[index].record.recordID.recordName
            try? moc.save()
        }
    }
}
