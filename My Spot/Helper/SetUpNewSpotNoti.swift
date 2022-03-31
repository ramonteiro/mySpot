//
//  SetUpNewSpotNoti.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/29/22.
//

import SwiftUI
import MapKit

struct SetUpNewSpotNoti: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var radius: CGFloat = UIScreen.screenWidth / 2
    @State private var centerRegion = MKCoordinateRegion()
    @State private var locations = [MKPointAnnotation]()
    @State private var distance: String = "Diameter: "
    @State private var isMetric = false
    @Binding var newPlace: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                MapView(centerRegion: $centerRegion, annotations: locations)
                Cross(radius: $radius)
                    .stroke(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    .frame(width: radius*2, height: radius*2)
            }
            .onAppear {
                isMetric = getIsMetric()
                if (UserDefaults.standard.valueExists(forKey: "discovernotiy")) {
                    let y = UserDefaults.standard.double(forKey: "discovernotiy")
                    let x = UserDefaults.standard.double(forKey: "discovernotix")
                    let location = CLLocationCoordinate2D(latitude: x, longitude: y)
                    print(location)
                    let newRegion = MKCoordinateRegion(center: location, span: mapViewModel.region.span)
                    centerRegion = newRegion
                } else {
                    centerRegion = mapViewModel.region
                }
            }
            .onChange(of: centerRegion.spanLatitude) { newValue in
                if isMetric {
                    let km = newValue.converted(to: .kilometers).value
                    if km < 1 {
                        distance = "Diameter: " + String(format: "%.2f", newValue.converted(to: .meters).value) + "m"
                    } else {
                        distance = "Diameter: " + String(format: "%.2f", km) + "km"
                    }
                } else {
                    let mi = newValue.converted(to: .miles).value
                    if mi < 1 {
                        distance = "Diameter: " + String(format: "%.2f", newValue.converted(to: .feet).value) + "ft"
                    } else {
                        distance = "Diameter: " + String(format: "%.2f", mi) + "mi"
                    }
                }
            }
            .interactiveDismissDisabled()
            .ignoresSafeArea()
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let distanceKm = centerRegion.spanLatitude.converted(to: .meters).value / 2
                        let location = CLLocation(latitude: centerRegion.center.latitude, longitude: centerRegion.center.longitude)
                        var placeName: String = ""
                        mapViewModel.getPlacmarkOfLocation(location: location) { l in
                            placeName = l
                            UserDefaults.standard.set(placeName, forKey: "discovernotiname")
                            newPlace.toggle()
                        }
                        UserDefaults.standard.set(Double(centerRegion.center.latitude), forKey: "discovernotix")
                        UserDefaults.standard.set(Double(centerRegion.center.longitude), forKey: "discovernotiy")
                        UserDefaults.standard.set(Double(distanceKm), forKey: "discovernotikm")
                        
                        cloudViewModel.unsubscribe(id: "NewSpotDiscover")
                        cloudViewModel.subscribeToNewSpot(fixedLocation: location, radiusInKm: distanceKm)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Text("\(distance)")
                        .foregroundColor(.white)
                        .padding([.leading,.trailing])
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.gray)
                                .opacity(0.5)
                        )
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Cancel", role: .destructive) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func getIsMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}

struct Cross: Shape {
    @Binding var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: rect.midX, y: 0))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.move(to: CGPoint(x: rect.midX, y: rect.midY))
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: radius, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 360), clockwise: false)
        }
    }
}

struct MapView: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var centerRegion: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> some MKMapView {
        let mapView = MKMapView()
        mapView.showsCompass = false
        mapView.showsUserLocation = mapViewModel.isAuthorized
        if (UserDefaults.standard.valueExists(forKey: "discovernotiy")) {
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
