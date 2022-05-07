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
    @ObservedObject var watchViewModel: WatchViewModel
    @State private var spots: [Spot] = []
    @State private var hasLoaded = false
    @State private var isError = false
    @StateObject var cloudViewModel = CloudKitViewModel()
    
    var body: some View {
        VStack {
            if spots.isEmpty && !hasLoaded && !isError {
                Text("Searching...".localized())
            } else if spots.isEmpty && hasLoaded && !isError {
                Text("No Spots Found".localized())
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Try expanding your search.".localized())
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            } else if spots.isEmpty && isError {
                Text("Error Loading Spots".localized())
                    .multilineTextAlignment(.center)
                    .padding(.vertical)
                Text("Please check connection and try again".localized())
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
            } else {
                List {
                    ForEach(spots, id: \.self) { spot in
                        NavigationLink(destination: DetailView(mapViewModel: mapViewModel, watchViewModel: watchViewModel, spot: spot)) {
                            RowView(spot: spot)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button {
                                        let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
                                        routeMeTo.name = spot.name
                                        routeMeTo.openInMaps(launchOptions: nil)
                                    } label: {
                                        Image(systemName: "location.fill")
                                            .font(.subheadline)
                                    }
                                    .tint(.green)
                                }
                                .if(watchViewModel.session.isReachable) { view in
                                    view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            if (watchViewModel.session.isReachable) {
                                                watchViewModel.sendSpotId(id: spot.spotid)
                                            }
                                        } label: {
                                            Image(systemName: "icloud.and.arrow.down")
                                        }
                                        .tint(.blue)
                                    }
                                }
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

extension View {
    
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
