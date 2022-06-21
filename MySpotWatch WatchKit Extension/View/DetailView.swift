//
//  DetailView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI
import MapKit

struct DetailView: View {
    
    let spot: Spot
    @ObservedObject var mapViewModel: WatchLocationManager
    @ObservedObject var watchViewModel: WatchViewModel
    @State private var away = ""
    @State private var didSend = false
    @State private var showingDescription = false
    @State private var spotRegion = DefaultLocations.region
    
    var body: some View {
        ScrollView {
            spotImage
            nameText
            if !spot.locationName.isEmpty {
                locationName
            }
            distanceAwayText
            if (!spot.description.isEmpty) {
                descriptionButton
            }
            mapView
            routeButton
            if (watchViewModel.session.isReachable && !didSend) {
                downloadButton
            }
        }
        .sheet(isPresented: $showingDescription) {
            DescriptionView(description: spot.description)
        }
        .onAppear {
            initializeVars()
        }
        
    }
    
    // MARK: - Sub Views
    
    private var spotImage: some View {
        Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: WKInterfaceDevice.current().screenBounds.size.width - 20)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(myColor(), lineWidth: 4)
            )
            .padding(.vertical)
    }
    
    private var nameText: some View {
        Text(spot.name)
            .font(.headline)
            .fontWeight(.bold)
    }
    
    private var locationName: some View {
        HStack {
            Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                .font(.subheadline)
            Text(spot.locationName)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
    
    private var distanceAwayText: some View {
        Text(away + " away".localized())
            .font(.subheadline)
            .lineLimit(1)
    }
    
    private var descriptionButton: some View {
        Button {
            showingDescription.toggle()
        } label: {
            Image(systemName: "note.text")
                .font(.subheadline)
            Text("Description".localized())
                .font(.subheadline)
                .lineLimit(1)
        }
    }
    
    private var mapView: some View {
        Map(coordinateRegion: $spotRegion, interactionModes: [], showsUserLocation: false, annotationItems: [SinglePin(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y))]) { location in
            MapMarker(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y), tint: .red)
        }
        .frame(width: WKInterfaceDevice.current().screenBounds.size.width - 20, height: WKInterfaceDevice.current().screenBounds.size.width - 20)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(myColor(), lineWidth: 4)
        )
        .padding(.vertical)
    }
    
    private var routeButton: some View {
        Button {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y)))
            routeMeTo.name = spot.name
            routeMeTo.openInMaps(launchOptions: nil)
        } label: {
            HStack {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                Text(spot.name)
                    .font(.subheadline)
            }
        }
    }
    
    private var downloadButton: some View {
        Button {
            watchViewModel.sendSpotId(id: spot.spotid)
            withAnimation {
                didSend.toggle()
            }
        } label: {
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.subheadline)
                Text("Download".localized())
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: - Functions
    
    private func initializeVars() {
        away = mapViewModel.calculateDistance(x: spot.x, y: spot.y)
        spotRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: spot.x, longitude: spot.y), span: DefaultLocations.spanFar)
    }
    
    private func myColor() -> Color {
        let systemColorArray: [Color] = [.red,.green,.pink,.blue,.indigo,.mint,.orange,.purple,.teal,.yellow, .gray]
        return (!(UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.valueExists(forKey: "colora") ?? false) ? .red :
                    ((UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0) != systemColorArray.count - 1) ? systemColorArray[UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.integer(forKey: "colorIndex") ?? 0] : Color(uiColor: UIColor(red: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorr") ?? 0), green: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorg") ?? 0), blue: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colorb") ?? 0), alpha: (UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.double(forKey: "colora") ?? 0))))
    }
}
