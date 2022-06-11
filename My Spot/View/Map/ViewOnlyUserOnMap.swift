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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @Binding var customLocation: Bool
    @Binding var locationName: String
    @State private var locations = [MKPointAnnotation]()
    @Binding var centerRegion: MKCoordinateRegion
    @State private var map = MKMapView()
    @State private var mapImageToggle = "square.2.stack.3d.top.filled"
    private let padding: CGFloat = 10
    
    @State private var presentCustomCoordinatesSheet = false
    @State private var didSet = false
    @State private var customCoordinates: CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    @State private var searchText: String = ""
    @State private var places: [Place] = []
    
    var body: some View {
        ZStack {
            MapViewCreateSpot(centerRegion: $centerRegion, map: $map, annotations: locations)
                .ignoresSafeArea()
            if customLocation {
                pinOverlayShape
            }
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !places.isEmpty {
                searchList
            }
            buttonOverlays
        }
        .onChange(of: searchText) { text in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if text == searchText {
                    Task {
                        await self.searchQuery()
                    }
                }
            }
        }
        .sheet(isPresented: $presentCustomCoordinatesSheet) {
            if didSet {
                map.setRegion(MKCoordinateRegion(center: customCoordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
                didSet = false
            }
        } content: {
            customCoordinatesSheet(customCoordinates: $customCoordinates, didSet: $didSet)
        }
        .onAppear {
            mapViewModel.checkLocationAuthorization()
        }
        .gesture(DragGesture()
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
    }
    
    private var searchList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 15) {
                ForEach(places) { place in
                    Text(place.place.name ?? "")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Divider()
                }
            }
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
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
                Button("Save".localized()) {
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            MapSearchBar(searchText: $searchText)
                .frame(width: UIScreen.screenWidth - (padding * 2))
                .shadow(radius: 20)
                .offset(y: customLocation ? 0 : -200)
            Spacer()
        }
        .padding(.horizontal, padding)
    }
    
    private var bottomRow: some View {
        HStack {
            VStack(spacing: padding * 1.5) {
                Spacer()
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
                        .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
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
                        .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
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
        .opacity(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1 : 0)
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
    
    private func searchQuery() async {
        
        places.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        do {
            let response = try await MKLocalSearch(request: request).start()
            self.places = response.mapItems.map { item in
                return Place(place: item.placemark)
            }
        } catch {
            print(error)
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

struct Place: Identifiable {
    
    let id = UUID().uuidString
    let place: CLPlacemark
}
