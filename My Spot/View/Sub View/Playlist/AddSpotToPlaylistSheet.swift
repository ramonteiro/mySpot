//
//  AddSpotToPlaylistSheet.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/24/22.
//

/*
 AddSpotToPlaylistSheet:
 displays spots to add to a playlist and allows user to select and add spots
 */

import SwiftUI
import CoreData

struct AddSpotToPlaylistSheet: View {
    
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.presentationMode) var presentationMode
    @State private var spotsFiltered: [Spot] = []
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.managedObjectContext) var moc
    var currPlaylist: Playlist
    @State private var addedSpots: [NSManagedObject] = []
    private let stack = CoreDataStack.shared
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if (!spotsFiltered.isEmpty) {
                    availableSpots
                } else {
                    messageNoSpotsAvailable
                }
                if (isSaving) {
                    ProgressView("Saving".localized())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
            .onAppear {
                spotsFiltered = spots.filter{ spot in
                    !spot.isShared && (spot.userId == UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") || spot.userId == "" || spot.userId == nil)
                }
            }
        }
        .navigationViewStyle(.automatic)
        .interactiveDismissDisabled()
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var availableSpots: some View {
        List(spotsFiltered) { spot in
            if (spot.playlist == nil) {
                SpotRow(spot: spot, isShared: addedSpots.contains(spot))
                    .onTapGesture {
                        if addedSpots.contains(spot) {
                            addedSpots.remove(at: addedSpots.firstIndex(of: spot)!)
                        } else {
                            addedSpots.append(spot)
                        }
                    }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Save".localized()) {
                    if addedSpots.count > 0 {
                        isSaving = true
                        if stack.isShared(object: currPlaylist) {
                            if let share = stack.getShare(currPlaylist) {
                                stack.addToParentShared(children: addedSpots, parent: currPlaylist, share: share, userid: cloudViewModel.userID) { (results) in
                                    switch results {
                                    case .success():
                                        DispatchQueue.main.async {
                                            stack.save()
                                        }
                                        isSaving = false
                                        close()
                                    case .failure(let error):
                                        //TODO: Failed to save share
                                        print("failed: \(error)")
                                        close()
                                    }
                                }
                            } else {
                                //TODO: Failed to save share
                                close()
                            }
                        } else {
                            for object in addedSpots {
                                let spot = object as! Spot
                                spot.playlist = currPlaylist
                            }
                            DispatchQueue.main.async {
                                stack.save()
                            }
                            isSaving = false
                            close()
                        }
                    } else {
                        close()
                    }
                }
                .padding()
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button("Cancel".localized()) {
                    close()
                }
                .padding()
            }
        }
        .navigationTitle("Add Spots".localized())
    }
    
    private var messageNoSpotsAvailable: some View {
        HStack {
            Spacer()
            Text("No Spots Available To Add".localized())
            Spacer()
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Done".localized()) {
                    close()
                }
                .padding()
            }
        }
        .navigationTitle("Add Spots".localized())
    }
}
