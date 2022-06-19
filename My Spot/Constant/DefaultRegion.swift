//
//  DefaultRegion.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import MapKit

enum DefaultLocations {
    static let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    static let spanClose = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    static let spanFar = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    static let spanSuperClose = MKCoordinateSpan(latitudeDelta: 0.007, longitudeDelta: 0.007)
}
