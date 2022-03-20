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
    @State private var count = 0
    
    var body: some View {
        NavigationView {
            if (!spots.isEmpty && count != 0) {
                availableSpots
            } else {
                messageNoSpotsAvailable
            }
        }
        .navigationViewStyle(.stack)
        .interactiveDismissDisabled()
        .onAppear {
            for i in spots {
                if let _ = i.playlist {
                    count += 1
                }
            }
            count = spots.count - count
        }
    }
    
    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private var availableSpots: some View {
        List(spots) { spot in
            if (spot.playlist == nil) {
                SpotRow(spot: spot)
                    .onTapGesture {
                        spot.playlist = currPlaylist
                        count -= 1
                    }
            }
        }
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
    
    private var messageNoSpotsAvailable: some View {
        HStack {
            Spacer()
            Text("No Spots Available To Add")
            Spacer()
        }
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
