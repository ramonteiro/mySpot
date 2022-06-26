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
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.presentationMode) var presentationMode
    let currPlaylist: Playlist
    let currentSpots: [String]
    @State private var spotsFiltered: [Spot] = []
    @State private var addedSpots: [NSManagedObject] = []
    @Binding var isSaving: Bool
    @Binding var errorSaving: Bool
    
    var body: some View {
        NavigationView {
            addSpotView
                .onAppear {
                    filterSpots()
                }
        }
        .navigationViewStyle(.automatic)
        .interactiveDismissDisabled()
    }
    
    // MARK: - Sub Views
    
    @ViewBuilder
    private var addSpotView: some View {
        if (!spotsFiltered.isEmpty) {
            availableSpots
        } else {
            messageNoSpotsAvailable
        }
    }
    
    private var availableSpots: some View {
        List(0..<spotsFiltered.count, id: \.self) { i in
            if (spotsFiltered[i].playlist == nil) {
                HStack {
                    Spacer()
                    ZStack {
                        MapSpotPreview(spot: $spotsFiltered[i])
                            .scaleEffect(0.9)
                        if addedSpots.contains(spotsFiltered[i]) {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.square.fill")
                                    .foregroundColor(.green)
                                    .font(.headline)
                            }
                            .padding(.trailing, 20)
                        }
                    }
                    Spacer()
                }
                .onTapGesture {
                    if addedSpots.contains(spotsFiltered[i]) {
                        addedSpots.remove(at: addedSpots.firstIndex(of: spotsFiltered[i])!)
                    } else {
                        addedSpots.append(spotsFiltered[i])
                    }
                }
                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                .listRowBackground(Color(uiColor: UIColor.systemBackground))
            }
        }
        .listStyle(.plain)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                saveButton
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                cancelButton
            }
        }
        .navigationTitle("Add Spots".localized())
    }
    
    private var cancelButton: some View {
        Button("Cancel".localized()) {
            presentationMode.wrappedValue.dismiss()
        }
        .padding()
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            save()
        }
        .padding()
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
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
        }
        .navigationTitle("Add Spots".localized())
    }
    
    // MARK: - Functions
    
    private func save() {
        if addedSpots.count > 0 {
            isSaving = true
            presentationMode.wrappedValue.dismiss()
            if CoreDataStack.shared.isShared(object: currPlaylist) {
                if let share = CoreDataStack.shared.getShare(currPlaylist) {
                    CoreDataStack.shared.addToParentShared(children: addedSpots, parent: currPlaylist, share: share, userid: cloudViewModel.userID) { (results) in
                        switch results {
                        case .success():
                            DispatchQueue.main.async {
                                CoreDataStack.shared.save()
                            }
                            isSaving = false
                        case .failure(let error):
                            errorSaving = true
                            print("failed: \(error)")
                            isSaving = false
                        }
                    }
                } else {
                    errorSaving = true
                    isSaving = false
                }
            } else {
                for object in addedSpots {
                    let spot = object as! Spot
                    spot.playlist = currPlaylist
                }
                DispatchQueue.main.async {
                    CoreDataStack.shared.save()
                }
                isSaving = false
            }
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func filterSpots() {
        spotsFiltered = spots.filter { spot in
            !spot.isShared &&
            (!currentSpots.contains("\(spot.name ?? "name")\(spot.x + spot.y)"))
        }
    }
}
