//
//  ListView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct ListView: View {
    
    let distance: Double
    let maxLoad: Int
    @ObservedObject var mapViewModel: WatchLocationManager
    @State private var spots: [Spot] = []
    @State private var hasLoaded = false
    @State private var isError = false
    @StateObject var cloudViewModel = CloudKitViewModel()
    
    var body: some View {
        VStack {
            if spots.isEmpty && !hasLoaded && !isError {
                Text("Searching...")
            } else if spots.isEmpty && hasLoaded && !isError {
                Text("No Spots Found")
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Try expanding your search.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            } else if spots.isEmpty && isError {
                Text("Error Loading Spots")
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Please check connection and try again")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            } else {
                List {
                    ForEach(spots, id: \.self) { spot in
                        NavigationLink(destination: DetailView(mapViewModel: mapViewModel, spot: spot)) {
                            RowView(spot: spot)
                        }
                    }
                }
            }
        }
        .onAppear {
            if spots.isEmpty {
                hasLoaded = false
                isError = false
                cloudViewModel.fetchSpotPublic(userLocation: mapViewModel.location, resultLimit: maxLoad, distance: distance) { (results) in
                    switch results {
                    case .success(let spots):
                        self.spots = spots
                        hasLoaded = true
                    case .failure(let error):
                        print("cloudkit fetch error: \(error)")
                        isError = true
                    }
                }
            }
        }
    }
}
