//
//  NewSpotNotificationMapView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI
import MapKit

struct NewSpotNotificationMapView: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var centerRegion: MKCoordinateRegion
    
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NewSpotNotificationMapView
        
        init(_ parent: NewSpotNotificationMapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.centerRegion = mapView.region
        }
    }
}
