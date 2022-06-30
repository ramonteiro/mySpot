//
//  MapViewSpotsWithPreview.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/22/22.
//

import SwiftUI
import MapKit

struct MapViewSpotsWithPreview<T: SpotPreviewType>: UIViewRepresentable {
    
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Binding var map: MKMapView
    @Binding var centerRegion: MKCoordinateRegion
    @Binding var selectedAnnotation: Int
    @Binding var spots: [T]
    @Binding var selectedFromSwipes: Bool
    @Binding var selectedFromTap: Bool
    
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
        private var preventDoubleTrigger = false
        var parent: MapViewSpotsWithPreview
        
        init(_ parent: MapViewSpotsWithPreview) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation.isEqual(mapView.userLocation) { return nil }
            let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "something")
            annotationView.markerTintColor = UIColor(parent.cloudViewModel.systemColorArray[parent.cloudViewModel.systemColorIndex])
            annotationView.animatesWhenAdded = true
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation {
                deselectAllExcept(annotation)
                if !parent.selectedFromSwipes {
                    let selection = parent.spots.firstIndex(where: {
                        $0.locationPreview.coordinate.longitude == annotation.coordinate.longitude &&
                        $0.locationPreview.coordinate.latitude == annotation.coordinate.latitude &&
                        $0.namePreview == annotation.title
                    }) ?? 0
                    parent.selectedFromTap = true
                    parent.selectedAnnotation = selection
                } else {
                    parent.selectedFromSwipes = false
                }
            }
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.centerRegion = mapView.region
        }
        
        private func deselectAllExcept(_ annotation: MKAnnotation) {
            for annotaionToDeselect in parent.map.selectedAnnotations {
                if annotation.coordinate.latitude != annotaionToDeselect.coordinate.latitude &&
                    annotation.coordinate.longitude != annotaionToDeselect.coordinate.longitude &&
                    annotation.title != annotaionToDeselect.title {
                    parent.map.deselectAnnotation(annotaionToDeselect, animated: true)
                }
            }
        }
    }
}
