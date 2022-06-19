//
//  ShowMapView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/22/22.
//

/*
 AddSpotMap:
 displays map centered on user location and only displays user location
 */

import SwiftUI
import MapKit

struct AddSpotMap: View {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var customLocation: Bool
    @Binding var didSave: Bool
    @Binding var centerRegion: MKCoordinateRegion
    @State private var locations = [MKPointAnnotation]()
    @State private var map = MKMapView()
    @State private var mapImageToggle = "square.2.stack.3d.top.filled"
    @State private var presentCustomCoordinatesSheet = false
    @State private var presentSearchSheet = false
    @State private var landmarks: [Landmark] = [Landmark]()
    @State private var searchText: String = ""
    @State private var didSet = false
    @State private var customCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var customLocationCache = false
    @State private var didAppear = false
    private let padding: CGFloat = 10
    
    var body: some View {
        ZStack {
            MapViewCreateSpot(centerRegion: $centerRegion, map: $map, annotations: locations)
                .ignoresSafeArea()
            if customLocation {
                pinOverlayShape
            }
            buttonOverlays
        }
        .sheet(isPresented: $presentCustomCoordinatesSheet) {
            dismissCustomCoordinateSheet()
        } content: {
            CustomCoordinatesSheet(customCoordinates: $customCoordinates, didSet: $didSet)
        }
        .sheet(isPresented: $presentSearchSheet) {
            SearchSheetMaps(map: $map, landmarks: $landmarks, searchText: $searchText)
        }
        .onAppear {
            setCustomLocation()
        }
    }
    
    // MARK: - Sub Views
    
    private var buttonOverlays: some View {
        VStack {
            topRow
            Spacer()
            bottomRow
        }
        .padding(.bottom, padding * 2)
        .padding(.vertical, padding * 5)
    }
    
    private var topRow: some View {
        VStack(spacing: padding) {
            HStack {
                cancelButton
                Spacer()
                saveButton
            }
            Spacer()
        }
        .padding(.horizontal, padding)
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            didSave = true
            presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var cancelButton: some View {
        Button("Cancel".localized()) {
            customLocation = customLocationCache
            presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var leftSide: some View {
        VStack(spacing: padding * 1.5) {
            Spacer()
            searchButton
            customCoordinateButton
        }
    }
    
    private var searchButton: some View {
        Button {
            presentSearchSheet.toggle()
        } label: {
            Image(systemName: "location.magnifyingglass")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .clipShape(Circle())
                .offset(x: customLocation ? 0 : -100)
        }
    }
    
    private var customCoordinateButton: some View {
        Button {
            presentCustomCoordinatesSheet.toggle()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .clipShape(Circle())
                .offset(x: customLocation ? 0 : -100)
        }
    }
    
    private var myLocationButton: some View {
        Button {
            focusMap()
        } label: {
            Image(systemName: "location.fill")
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background(mapViewModel.isAuthorized ? cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] : .gray)
                .clipShape(Circle())
        }
        .disabled(!mapViewModel.isAuthorized)
    }
    
    private var toggleCustomLocationButton: some View {
        Button {
            withAnimation {
                customLocation.toggle()
            }
            if !customLocation {
                focusMap()
            }
        } label: {
            Image(systemName: (customLocation ? "mappin" : "figure.wave"))
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background(mapViewModel.isAuthorized ? cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex] : .gray)
                .clipShape(Circle())
        }
        .disabled(!mapViewModel.isAuthorized && customLocation)
    }
    
    private var toggleMapTypeButton: some View {
        Button {
            toggleMapType()
        } label: {
            Image(systemName: mapImageToggle)
                .font(.title2)
                .foregroundColor(.white)
                .padding(padding)
                .frame(width: 50, height: 50)
                .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .clipShape(Circle())
        }
    }
    
    private var rightSide: some View {
        VStack(spacing: padding * 1.5) {
            Spacer()
            myLocationButton
            toggleCustomLocationButton
            toggleMapTypeButton
        }
    }
    
    private var bottomRow: some View {
        HStack {
            leftSide
            Spacer()
            rightSide
        }
        .padding(.horizontal, padding)
    }
    
    private var pinOverlayShape: some View {
        ZStack {
            VStack {
                MapPin()
                    .frame(width: 40, height: 40)
                    .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                Spacer()
                    .frame(height: 50)
            }
            CustomMapCircle()
                .stroke(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
    }
    
    // MARK: - Functions
    
    private func toggleMapType() {
        if map.mapType == .standard {
            map.mapType = .hybrid
            withAnimation {
                mapImageToggle = "square.2.stack.3d.bottom.filled"
            }
        } else {
            map.mapType = .standard
            withAnimation {
                mapImageToggle = "square.2.stack.3d.top.filled"
            }
        }
    }
    
    private func focusMap() {
        map.setRegion(mapViewModel.region, animated: true)
    }
    
    private func setCustomLocation() {
        mapViewModel.checkLocationAuthorization()
        if !didAppear {
            customLocationCache = customLocation
        }
        didAppear = true
    }
    
    private func dismissCustomCoordinateSheet() {
        if didSet {
            map.setRegion(MKCoordinateRegion(center: customCoordinates, span: DefaultLocations.spanClose), animated: true)
            didSet = false
        }
    }
}
