//
//  ShowMapView.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/22/22.
//

/*
 ViewOnlyUserOnMap:
 displays map centered on user location and only displays user location
 */

import SwiftUI
import MapKit

struct ViewOnlyUserOnMap: View {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Environment(\.presentationMode) var presentationMode
    @Binding var customLocation: Bool
    @Binding var didSave: Bool
    @State private var locations = [MKPointAnnotation]()
    @Binding var centerRegion: MKCoordinateRegion
    @State private var map = MKMapView()
    @State private var mapImageToggle = "square.2.stack.3d.top.filled"
    private let padding: CGFloat = 10
    
    @State private var presentCustomCoordinatesSheet = false
    @State private var presentSearchSheet = false
    @State private var landmarks: [Landmark] = [Landmark]()
    @State private var searchText: String = ""
    @State private var didSet = false
    @State private var customCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State private var customLocationCache = false
    @State private var didAppear = false
    
    var body: some View {
        ZStack {
            MapViewCreateSpot(centerRegion: $centerRegion, map: $map, annotations: locations)
                .ignoresSafeArea()
            if customLocation {
                pinOverlayShape
            }
            buttonOverlays
                .padding(.vertical, padding * 4)
        }
        .sheet(isPresented: $presentCustomCoordinatesSheet) {
            if didSet {
                map.setRegion(MKCoordinateRegion(center: customCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
                didSet = false
            }
        } content: {
            customCoordinatesSheet(customCoordinates: $customCoordinates, didSet: $didSet)
        }
        .sheet(isPresented: $presentSearchSheet) {
            SearchSheetMaps(map: $map, landmarks: $landmarks, searchText: $searchText)
        }
        .onAppear {
            mapViewModel.checkLocationAuthorization()
            if !didAppear {
                customLocationCache = customLocation
            }
            didAppear = true
        }
    }
    
    private var buttonOverlays: some View {
        VStack {
            topRow
            Spacer()
            bottomRow
        }
        .padding(.top, padding)
        .padding(.bottom, padding * 3)
    }
    
    private var topRow: some View {
        VStack(spacing: padding) {
            HStack {
                Button("Cancel".localized()) {
                    customLocation = customLocationCache
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Save".localized()) {
                    didSave = true
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding(.horizontal, padding)
    }
    
    private var bottomRow: some View {
        HStack {
            VStack(spacing: padding * 1.5) {
                Spacer()
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
            Spacer()
            VStack(spacing: padding * 1.5) {
                Spacer()
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
}

struct SearchSheetMaps: View {
    
    @Binding var map: MKMapView
    @Binding var landmarks: [Landmark]
    @Environment(\.presentationMode) var presentationMode
    @Binding var searchText: String
    
    var body: some View {
        VStack(spacing: 0) {
            MapSearchBar(searchText: $searchText)
                .padding(.vertical, 20)
            List {
                ForEach(landmarks, id: \.id) { landmark in
                    VStack(alignment: .leading) {
                        Text(landmark.name)
                            .fontWeight(.bold)
                        Text(landmark.title)
                    }
                    .onTapGesture {
                        if let location = landmark.placemark.location {
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                                map.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: true)
                            }
                        }
                    }
                }
            }
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

struct MapPin: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                              control: CGPoint(x: rect.minX, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                              control: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}

struct CustomMapCircle: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: 10, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360), clockwise: false)
        }
    }
}

struct customCoordinatesSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var customCoordinates: CLLocationCoordinate2D
    @Binding var didSet: Bool
    @State private var xString: String = ""
    @State private var yString: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Latitude(X)".localized(), text: $xString)
                    .keyboardType(.numberPad)
                TextField("Longitude(Y)".localized(), text: $yString)
                    .keyboardType(.numberPad)
            } header: {
                Text("Enter Coordinates".localized())
            } footer: {
                Text(errorMessage)
            }
            Button {
                if CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: CLLocationDegrees(Float(xString) ?? 0.0),
                                                                        longitude: CLLocationDegrees(Float(yString) ?? 0.0))) {
                    didSet = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    errorMessage = "Invalid Coordinates!".localized()
                }
            } label: {
                Text("Search".localized())
            }
        }
        .gesture(DragGesture()
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
    }
}

struct MapViewCreateSpot: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var centerRegion: MKCoordinateRegion
    @Binding var map: MKMapView
    var annotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> some MKMapView {
        let mapView = map
        mapView.showsCompass = false
        mapView.showsUserLocation = mapViewModel.isAuthorized
        mapView.setRegion(mapViewModel.region, animated: true)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if annotations.count != uiView.annotations.count {
            uiView.removeAnnotations(uiView.annotations)
            uiView.addAnnotations(annotations)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewCreateSpot
        
        init(_ parent: MapViewCreateSpot) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.centerRegion = mapView.region
        }
    }
}

struct MapSearchBar: View {
    
    @Binding var searchText: String
    @State private var canCancel: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(UIColor.secondarySystemBackground))
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search ".localized(), text: $searchText)
                    .submitLabel(.search)
                if (canCancel) {
                    Spacer()
                    Image(systemName: "xmark")
                        .padding(5)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .onTapGesture {
                            UIApplication.shared.dismissKeyboard()
                            searchText = ""
                        }
                        .padding(.trailing, 13)
                }
            }
            .foregroundColor(.gray)
            .padding(.leading, 13)
        }
        .frame(height: 40)
        .cornerRadius(13)
        .padding(.horizontal)
        .onAppear {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                canCancel = true
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation(.easeInOut(duration: 0.2)) {
                    canCancel = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    canCancel = false
                }
            }
        }
    }
}

struct Landmark {
    
    let placemark: MKPlacemark
    
    var id: UUID {
        return UUID()
    }
    
    var name: String {
        self.placemark.name ?? ""
    }
    
    var title: String {
        self.placemark.title ?? ""
    }
    
    var coordinate: CLLocationCoordinate2D {
        self.placemark.coordinate
    }
}
