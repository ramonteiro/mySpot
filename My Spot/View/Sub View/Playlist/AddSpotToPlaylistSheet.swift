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

struct AddSpotToPlaylistSheet: View {
    @FetchRequest(sortDescriptors: []) var spots: FetchedResults<Spot>
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    var currPlaylist: Playlist
    
    var body: some View {
        NavigationView {
            if (!spots.isEmpty) {
                displayAvailableSpots
            } else {
                displayMessageNoSpotsAvailable
            }
        }
        .interactiveDismissDisabled()
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var displayAvailableSpots: some View {
        List(spots) { spot in
            if (spot.playlist == nil) {
                SpotRow(spot: spot)
                    .onTapGesture {
                        spot.playlist = currPlaylist
                    }
            }
        }
        .accentColor(.red)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Done") {
                    try? moc.save()
                    close()
                }
                .padding()
            }
        }
        .navigationTitle("Add Spots")
    }
    
    private var displayMessageNoSpotsAvailable: some View {
        HStack {
            Spacer()
            Text("No Spots Available To Add")
            Spacer()
        }
        .accentColor(.red)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("Done") {
                    close()
                }
                .padding()
            }
        }
        .navigationTitle("Add Spots")
    }
}
