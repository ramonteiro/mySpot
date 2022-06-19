//
//  AddSpotMapView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI
import MapKit

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
