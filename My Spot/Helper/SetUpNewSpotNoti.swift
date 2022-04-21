//
//  SetUpNewSpotNoti.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/29/22.
//

import SwiftUI
import MapKit
import Combine

struct SetUpNewSpotNoti: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var centerRegion = MKCoordinateRegion()
    @State private var locations = [MKPointAnnotation]()
    @State private var distance: String = "Diameter: ".localized()
    @State private var isMetric = false
    @State private var saving: Bool = false
    @Binding var newPlace: Bool
    @Binding var unableToAddSpot: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(centerRegion: $centerRegion, annotations: locations, isForNotifications: true)
                Cross()
                    .stroke(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                if (saving) {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Saving".localized())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
            .onAppear {
                isMetric = getIsMetric()
                if (UserDefaults.standard.valueExists(forKey: "discovernotiy")) {
                    let y = UserDefaults.standard.double(forKey: "discovernotiy")
                    let x = UserDefaults.standard.double(forKey: "discovernotix")
                    let location = CLLocationCoordinate2D(latitude: x, longitude: y)
                    let newRegion = MKCoordinateRegion(center: location, span: mapViewModel.region.span)
                    centerRegion = newRegion
                } else {
                    centerRegion = mapViewModel.region
                }
            }
            .interactiveDismissDisabled()
            .ignoresSafeArea()
            .navigationViewStyle(.automatic)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Save".localized()) {
                        Task {
                            let location = CLLocation(latitude: centerRegion.center.latitude, longitude: centerRegion.center.longitude)
                            saving = true
                            var placeName: String = ""
                            mapViewModel.getPlacmarkOfLocationLessPrecise(location: location) { l in
                                placeName = l
                            }
                            
                            // check permissions
                            await cloudViewModel.checkNotificationPermission()
                            if cloudViewModel.notiPermission == 0 { // not determined
                                // ask
                                await cloudViewModel.requestPermissionNoti()
                            }
                            if cloudViewModel.notiPermission == 2 ||  cloudViewModel.notiPermission == 3 { // allowed
                                
                                // sub
                                do {
                                    try await cloudViewModel.subscribeToNewSpot(fixedLocation: location)
                                    UserDefaults.standard.set(placeName, forKey: "discovernotiname")
                                    newPlace.toggle()
                                    UserDefaults.standard.set(Double(centerRegion.center.latitude), forKey: "discovernotix")
                                    UserDefaults.standard.set(Double(centerRegion.center.longitude), forKey: "discovernotiy")
                                } catch { // no connection
                                    unableToAddSpot = 1
                                }
                            } else { // not allowed
                                unableToAddSpot = 2
                            }
                            saving = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    VStack {
                        Text("Radius: 10 Miles".localized())
                            .foregroundColor(.white)
                            .padding([.leading,.trailing])
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.gray)
                                    .opacity(0.5)
                            )
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel".localized(), role: .destructive) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving)
                }
            }
        }
    }
    
    private func getIsMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}

struct Cross: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: 10, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360), clockwise: false)
        }
    }
}

struct MapView: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var centerRegion: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    var isForNotifications: Bool
    
    func makeUIView(context: Context) -> some MKMapView {
        let mapView = MKMapView()
        mapView.showsCompass = false
        mapView.showsUserLocation = mapViewModel.isAuthorized
        if (UserDefaults.standard.valueExists(forKey: "discovernotiy") && isForNotifications) {
            let y = UserDefaults.standard.double(forKey: "discovernotiy")
            let x = UserDefaults.standard.double(forKey: "discovernotix")
            let location = CLLocationCoordinate2D(latitude: x, longitude: y)
            let newRegion = MKCoordinateRegion(center: location, span: mapViewModel.region.span)
            mapView.setRegion(newRegion, animated: true)
        } else {
            mapView.setRegion(mapViewModel.region, animated: true)
        }
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
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.centerRegion = mapView.region
        }
    }
}
