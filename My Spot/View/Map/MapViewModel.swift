//
//  MapViewModel.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/21/22.
//

/*
 MapViewModel:
 checks if location services are enabled
 */

import SwiftUI
import MapKit

final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    var locationManager: CLLocationManager?
    @Published var isAuthorized: Bool = false
    @Published var searchingHere = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 33.714712646421, longitude: -112.29072718706581), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
    override init() {
        super.init()
        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.lastKnownUserLocationX)) {
            searchingHere.center.longitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationY)
            searchingHere.center.latitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationX)
        }
        self.checkIfLocationServicesIsEnabled()
    }
    
    private func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
            
        case .notDetermined:
            isAuthorized = false
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            isAuthorized = false
            setPreviousLocation()
        case .denied:
            isAuthorized = false
            setPreviousLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            if let center = locationManager.location?.coordinate {
                isAuthorized = true
                region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                UserDefaults.standard.set(region.center.latitude, forKey: UserDefaultKeys.lastKnownUserLocationX)
                UserDefaults.standard.set(region.center.longitude, forKey: UserDefaultKeys.lastKnownUserLocationY)
            } else {
                isAuthorized = false
                setPreviousLocation()
            }
        @unknown default:
            isAuthorized = false
            setPreviousLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func getIsAuthorized() -> Bool {
        return isAuthorized
    }
    
    private func setPreviousLocation() {
        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.lastKnownUserLocationX)) {
            region.center.latitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationX)
            region.center.longitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationY)
        }
    }
    
    func getPlacmarkOfLocation(location: CLLocation, completionHandler: @escaping (String) -> Void) {
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(location) { (placemarker, error) in
            if error == nil {
                let place = placemarker?[0]
                if let local = place?.locality {
                    completionHandler(local)
                } else if let country = place?.country {
                    completionHandler(country)
                } else if let ocean = place?.ocean {
                    completionHandler(ocean)
                } else {
                    completionHandler(" ")
                }
            } else {
                completionHandler(" ")
            }
        }
    }
}
