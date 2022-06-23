//
//  MapViewSpotsWithPreview.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/22/22.
//

import SwiftUI
import MapKit

struct MapViewSpotsWithPreview: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @Binding var map: MKMapView
    @Binding var selectedAnnotation: Int
    
    func makeUIView(context: Context) -> some MKMapView {
        let mapView = map
        mapView.showsCompass = false
        mapView.showsUserLocation = mapViewModel.isAuthorized
        mapView.setRegion(mapViewModel.region, animated: true)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewSpotsWithPreview
        
        init(_ parent: MapViewSpotsWithPreview) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            if let view = mapView.dequeueReusableAnnotationView(withIdentifier: "custom") {
                view.annotation = annotation
                return view
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation {
                let allAnnotations = parent.map.annotations
                let index = allAnnotations.firstIndex(where: { $0.coordinate.latitude == annotation.coordinate.latitude })
                if let index = index, parent.selectedAnnotation != index {
                    parent.selectedAnnotation = index
                }
            }
        }
    }
}
