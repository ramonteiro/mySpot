//
//  ViewDiscoverSpots.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 ViewDiscoverSpots:
 Displays map for discover tab
 */

import SwiftUI
import MapKit
import Combine
import CoreData

struct ViewDiscoverSpots: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var selection = 0
    @State private var originalRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    @State private var transIn: Edge = .leading
    @State private var transOut: Edge = .bottom
    @State private var showingDetailsSheet = false
    @State private var fadeInOut = false
    @State private var spotRegion: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    var body: some View {
        ZStack {
            displayMap
        }
        .onAppear {
            withAnimation {
                spotRegion = mapViewModel.region
            }
            originalRegion = spotRegion
        }
    }

    func close() {
        presentationMode.wrappedValue.dismiss()
    }
    
    private func increaseSelection() {
        if cloudViewModel.spots.count == selection+1 {
            selection = 0
        } else {
            selection+=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private func decreaseSelection() {
        if 0 > selection-1 {
            selection = cloudViewModel.spots.count-1
        } else {
            selection-=1
        }
        withAnimation {
            spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
    }
    
    private var displayRouteButon: some View {
        Button(action: {
            let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: cloudViewModel.spots[selection].location.coordinate))
            routeMeTo.name = cloudViewModel.spots[selection].name
            routeMeTo.openInMaps(launchOptions: nil)
        }) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMyLocationButton: some View {
        Button(action: {
            withAnimation {
                spotRegion = mapViewModel.region
            }
        }) {
            Image(systemName: "location").imageScale(.large)
        }
        .disabled(!mapViewModel.isAuthorized)
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayBackButton: some View {
        Button(action: close ) {
            Image(systemName: "arrowshape.turn.up.backward").imageScale(.large)
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
    
    private var displayMap: some View {
        ZStack {
            Map(coordinateRegion: $spotRegion, interactionModes: [.pan, .zoom], showsUserLocation: mapViewModel.getIsAuthorized(), annotationItems: cloudViewModel.spots, annotationContent: { location in
                MapAnnotation(coordinate: location.location.coordinate) {
                    MapAnnotationDiscover(spot: location)
                        .scaleEffect(cloudViewModel.spots[selection] == location ? 1.2 : 0.9)
                        .shadow(radius: 8)
                        .onTapGesture {
                            transIn = .bottom
                            transOut = .bottom
                            selection = cloudViewModel.spots.firstIndex(of: location) ?? 0
                            withAnimation {
                                spotRegion = MKCoordinateRegion(center: cloudViewModel.spots[selection].location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                            }
                        }
                }
            })
            .ignoresSafeArea()
            VStack {
                HStack {
                    VStack(spacing: 0) {
                        displayBackButton
                        Spacer()
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        if ((spotRegion.center.latitude > originalRegion.center.latitude + 0.03 || spotRegion.center.latitude < originalRegion.center.latitude - 0.03) ||
                            (spotRegion.center.longitude > originalRegion.center.longitude + 0.03 || spotRegion.center.longitude < originalRegion.center.longitude - 0.03)) {
                            displaySearchButton
                                .transition(.opacity.animation(.easeInOut(duration: 0.6)))
                            Spacer()
                        }
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        displayMyLocationButton
                        displayRouteButon
                        Spacer()
                    }
                }
                .padding()
                Spacer()
                
                ZStack {
                    ForEach(cloudViewModel.spots, id: \.self) { spot in
                        if (spot == cloudViewModel.spots[selection]) {
                            DiscoverMapPreview(spot: spot)
                                .shadow(color: Color.black.opacity(0.3), radius: 10)
                                .padding()
                                .onTapGesture {
                                    showingDetailsSheet.toggle()
                                }
                                .transition(.asymmetric(insertion: .move(edge: transIn), removal: .move(edge: transOut)))
                                .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                            .onEnded({ value in
                                                withAnimation {
                                                    if value.translation.width < 0 {
                                                        transIn = .trailing
                                                        transOut = .bottom
                                                        increaseSelection()
                                                    }

                                                    if value.translation.width > 0 {
                                                        transIn = .leading
                                                        transOut = .bottom
                                                        decreaseSelection()
                                                    }
                                                }
                                            }))
                        }
                    }
                }
            }
        }
        .accentColor(.red)
        .sheet(isPresented: $showingDetailsSheet) {
            DetailsDiscoverSheet(spot: cloudViewModel.spots[selection])
        }
    }
    
    private var displaySearchButton: some View {
        Button(action: {
            cloudViewModel.fetchSpotPublic(userLocation: CLLocation(latitude: spotRegion.center.latitude, longitude: spotRegion.center.longitude), type: "none")
            originalRegion = spotRegion
            mapViewModel.searchingHere = spotRegion
        }) {
            Text("Search Here")
        }
        .shadow(color: Color.black.opacity(0.3), radius: 10)
        .buttonStyle(.borderedProminent)
    }
}


struct DetailsDiscoverSheet: View {
    
    var spot: SpotFromCloud
    @Environment(\.managedObjectContext) var moc
    @EnvironmentObject var mapViewModel: MapViewModel
    
    @State private var isSaving = false
    @State private var newName = ""
    @State private var imageLoaded: Bool = false
    @State private var isSaved: Bool = false
    @FocusState private var nameIsFocused: Bool
    
    var body: some View {
        NavigationView {
            Form {
                if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .onAppear {
                            imageLoaded = true
                        }
                } else {
                    HStack {
                        Spacer()
                        ProgressView("Loading Image")
                        Spacer()
                    }
                    .onAppear {
                        imageLoaded = false
                    }
                }
                Text("Found by: \(spot.founder)\nOn \(spot.date)\nTag: \(spot.type)").font(.subheadline).foregroundColor(.gray)
                Section(header: Text("Description")) {
                    Text(spot.description)
                }
                Section(header: Text("Location")) {
                    ViewSingleSpotOnMap(singlePin: [SinglePin(name: spot.name, coordinate: CLLocationCoordinate2D(latitude: spot.location.coordinate.latitude, longitude: spot.location.coordinate.longitude))])
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                    Button("Take Me To \(spot.name)") {
                        let routeMeTo = MKMapItem(placemark: MKPlacemark(coordinate: spot.location.coordinate))
                        routeMeTo.name = spot.name
                        routeMeTo.openInMaps(launchOptions: nil)
                    }
                    .accentColor(.blue)
                }
                if (isSpotInCoreData().count == 0 && !isSaved) {
                    Section(header: Text("Save To My Spots")) {
                        if (!isSaving) {
                            Button("Save") {
                                isSaving = true
                            }
                            .disabled(!imageLoaded)
                            .accentColor(.blue)
                        }
                        if (isSaving) {
                            TextField("Enter Spot Name", text: $newName)
                                .focused($nameIsFocused)
                                .onReceive(Just(newName)) { _ in
                                    if (newName.count > MaxCharLength.names) {
                                        newName = String(newName.prefix(MaxCharLength.names))
                                    }
                                }
                            Button("Save") {
                                save()
                            }
                            .accentColor(.blue)
                            .disabled(newName == "")
                        }
                    }
                }
            }
            .navigationTitle(spot.name)
            .listRowSeparator(.hidden)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Done") {
                        nameIsFocused = false
                    }
                    .accentColor(.blue)
                }
            }
        }
    }
        
    private func isSpotInCoreData() -> [Spot] {
        let fetchRequest: NSFetchRequest<Spot> = Spot.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "dbid == %@", spot.record.recordID.recordName as CVarArg)
        do {
            let spotsFound: [Spot] = try moc.fetch(fetchRequest)
            return spotsFound
        } catch {
            return []
        }
    }
    
    private func save() {
        let url = spot.imageURL
        if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
            let newSpot = Spot(context: moc)
            newSpot.founder = spot.founder
            newSpot.details = spot.description
            newSpot.image = image
            newSpot.name = newName
            newSpot.x = spot.location.coordinate.latitude
            newSpot.y = spot.location.coordinate.longitude
            newSpot.isPublic = false
            newSpot.type = spot.type
            newSpot.date = spot.date
            newSpot.id = UUID()
            newSpot.dbid = spot.record.recordID.recordName
            try? moc.save()
            isSaved = true
        }
    }
}
