//
//  SearchSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI
import MapKit

struct SearchSheetMaps: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var map: MKMapView
    @Binding var landmarks: [Landmark]
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            MapSearchBar(searchText: $searchText)
                .padding(.vertical, 20)
            landmarkList
        }
        .gesture(DragGesture()
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
        .onChange(of: searchText) { text in
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                getNearByLandmarks()
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var landmarkList: some View {
        List {
            ForEach(landmarks, id: \.id) { landmark in
                landmarkRowView(landmark: landmark)
                .onTapGesture {
                    setMapRegion(landmark: landmark)
                }
            }
        }
    }
    
    private func landmarkRowView(landmark: Landmark) -> some View {
        VStack(alignment: .leading) {
            Text(landmark.name)
                .fontWeight(.bold)
            Text(landmark.title)
        }
    }
    
    // MARK: - Functions
    
    private func setMapRegion(landmark: Landmark) {
        if let location = landmark.placemark.location {
            withAnimation {
                presentationMode.wrappedValue.dismiss()
                map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: true)
            }
        }
    }
    
    private func getNearByLandmarks() {
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if let response = response {
                let mapItems = response.mapItems
                self.landmarks = mapItems.map {
                    Landmark(placemark: $0.placemark)
                }
            }
        }
    }
}
