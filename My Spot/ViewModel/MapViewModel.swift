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
    
    @Published var region = DefaultLocations.region
    var locationManager: CLLocationManager?
    @Published var isAuthorized: Bool = false
    @Published var searchingHere = DefaultLocations.region
    @Published var isMetric = false
    
    override init() {
        super.init()
        self.getIsMetric()
        self.setLastKnownLocation()
        self.checkIfLocationServicesIsEnabled()
    }
    
    private func getIsMetric() {
        isMetric = ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? false
    }
    
    private func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    func calculateDistance(from location: CLLocation) -> String {
        let userLocation = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
        let distanceInMeters = userLocation.distance(from: location)
        if isMetric {
            let distanceDouble = distanceInMeters / 1000
            return String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            return String(format: "%.1f", distanceDouble) + " mi"
        }
    }
    
    func distanceBetween(x1: Double, x2: Double, y1: Double, y2: Double) -> Double {
        return (((x2 - x1) * (x2 - x1))+((y2 - y1) * (y2 - y1))).squareRoot()
    }
    
    func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            isAuthorized = false
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            isAuthorized = false
            setLastKnownLocation()
        case .denied:
            isAuthorized = false
            setLastKnownLocation()
        case .authorizedAlways, .authorizedWhenInUse:
            if let center = locationManager.location?.coordinate {
                isAuthorized = true
                region = MKCoordinateRegion(center: center, span: DefaultLocations.spanClose)
                setLastKnownLocation()
            } else {
                isAuthorized = false
                setLastKnownLocation()
            }
        @unknown default:
            isAuthorized = false
            setLastKnownLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    private func setLastKnownLocation() {
        if (UserDefaults.standard.valueExists(forKey: UserDefaultKeys.lastKnownUserLocationX)) {
            searchingHere.center.longitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationY)
            searchingHere.center.latitude = UserDefaults.standard.double(forKey: UserDefaultKeys.lastKnownUserLocationX)
        } else {
            UserDefaults.standard.set(region.center.latitude, forKey: UserDefaultKeys.lastKnownUserLocationX)
            UserDefaults.standard.set(region.center.longitude, forKey: UserDefaultKeys.lastKnownUserLocationY)
        }
    }
    
    func getPlacmarkOfLocation(location: CLLocation, isPrecise: Bool, completionHandler: @escaping (String) -> Void) {
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(location) { (placemarker, error) in
            if error == nil {
                let place = placemarker?[0]
                if let sublocal = place?.subLocality, isPrecise {
                    completionHandler(sublocal)
                } else if let local = place?.locality {
                    completionHandler(local)
                } else if let state = place?.administrativeArea {
                    completionHandler(state)
                } else if let country = place?.country {
                    completionHandler(country)
                } else if let ocean = place?.ocean {
                    completionHandler(ocean)
                } else {
                    completionHandler("")
                }
            } else {
                completionHandler("")
            }
        }
    }
}
