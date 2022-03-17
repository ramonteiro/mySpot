//
//  DiscoverSheetShared.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/15/22.
//

import SwiftUI
import Combine
import CoreData
import MapKit

struct DiscoverSheetShared: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var likedIds: FetchedResults<Likes>
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    @State private var isSaving = false
    @State private var likes = 0
    @State private var likeButton = "hand.thumbsup"
    @State private var newName = ""
    @State private var imageLoaded: Bool = false
    @State private var isSaved: Bool = false
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        NavigationView {
            if (cloudViewModel.shared.count == 1) {
                Form {
                    if let url = cloudViewModel.shared[0].imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
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
                    Text("Found by: \(cloudViewModel.shared[0].founder)\nOn \(cloudViewModel.shared[0].date)\nTag: \(cloudViewModel.shared[0].type)").font(.subheadline).foregroundColor(.gray)
                    Section(header: Text("Description")) {
                        Text(cloudViewModel.shared[0].description)
                    }
                    Section(header: Text("Location")) {
                        ViewSingleSpotOnMap(singlePin: [SinglePin(name: cloudViewModel.shared[0].name, coordinate: CLLocationCoordinate2D(latitude: cloudViewModel.shared[0].location.coordinate.latitude, longitude: cloudViewModel.shared[0].location.coordinate.longitude))])
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                        Button("Take Me To \(cloudViewModel.shared[0].name)") {
                            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.shared[0].location.coordinate))
                            routeMeTo.name = cloudViewModel.shared[0].name
                            routeMeTo.openInMaps(launchOptions: nil)
                        }
                        .tint(.blue)
                    }
                    if (isSpotInCoreData().count == 0 && !isSaved) {
                        Section(header: Text("Save To My Spots")) {
                            if (!isSaving) {
                                Button("Save") {
                                    isSaving = true
                                }
                                .disabled(!imageLoaded)
                                .tint(.blue)
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
                                }
                                .tint(.blue)
                                .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            }
                        }
                    }
                }
                .onAppear {
                    var didlike = false
                    for i in likedIds {
                        if i.likedId == String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name {
                            didlike = true
                            break
                        }
                    }
                    if (didlike) {
                        likeButton = "hand.thumbsup.fill"
                    }
                }
                .navigationTitle(cloudViewModel.shared[0].name)
                .listRowSeparator(.hidden)
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
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Text("\(cloudViewModel.shared[0].likes)")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .offset(x: 26)
                        Button(action: {
                            if (likeButton == "hand.thumbsup") {
                                let newLike = Likes(context: moc)
                                newLike.likedId = String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name
                                try? moc.save()
                                likeButton = "hand.thumbsup.fill"
                                cloudViewModel.likeSpot(spot: cloudViewModel.shared[0], like: true)
                                cloudViewModel.shared[0].likes += 1
                            } else {
                                for i in likedIds {
                                    if (i.likedId == String(cloudViewModel.shared[0].location.coordinate.latitude + cloudViewModel.shared[0].location.coordinate.longitude) + cloudViewModel.shared[0].name) {
                                        moc.delete(i)
                                        try? moc.save()
                                        break
                                    }
                                }
                                likeButton = "hand.thumbsup"
                                cloudViewModel.likeSpot(spot: cloudViewModel.shared[0], like: false)
                                cloudViewModel.shared[0].likes -= 1
                            }
                            
                        }, label: {
                            Image(systemName: likeButton)
                        })
                        .padding()
                    }
                }
            }
        }
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
        let url = cloudViewModel.shared[0].imageURL
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            let newSpot = Spot(context: moc)
            newSpot.founder = cloudViewModel.shared[0].founder
            newSpot.details = cloudViewModel.shared[0].description
            newSpot.image = image
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
}
