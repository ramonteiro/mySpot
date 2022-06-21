//
//  LocationViewModel.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import CoreLocation
import WidgetKit

final class WidgetLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    var locationManager: CLLocationManager?
    private var handler: ((CLLocation) -> Void)?

    override init() {
        super.init()
        DispatchQueue.main.async {
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate = self
            if self.locationManager!.authorizationStatus == .notDetermined {
                self.locationManager!.requestWhenInUseAuthorization()
            }
        }
    }
    
    func getPlacmarkOfLocation(location: CLLocation, completionHandler: @escaping (String) -> Void) {
        let geo = CLGeocoder()
        geo.reverseGeocodeLocation(location) { (placemarker, error) in
            if error == nil {
                let place = placemarker?[0]
                if let sublocal = place?.subLocality {
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
    
    func fetchLocation(handler: @escaping (CLLocation) -> Void) {
        self.handler = handler
        self.locationManager!.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.handler!(locations.last!)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func calculateDistance(x: Double, y: Double, x2: Double, y2: Double) -> String {
        let userLocation = CLLocation(latitude: x2, longitude: y2)
        let spotLocation = CLLocation(latitude: x, longitude: y)
        let distanceInMeters = userLocation.distance(from: spotLocation)
        if isMetric() {
            let distanceDouble = distanceInMeters / 1000
            if distanceDouble >= 99 {
                return "99+ km"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " km"
            }
            return String(format: "%.1f", distanceDouble) + " km"
        } else {
            let distanceDouble = distanceInMeters / 1609.344
            if distanceDouble >= 99 {
                return "99+ mi"
            }
            if distanceDouble >= 10 {
                return String(Int(distanceDouble)) + " mi"
            }
            return String(format: "%.1f", distanceDouble) + " mi"
        }
        
    }
    
    private func isMetric() -> Bool {
        return ((Locale.current as NSLocale).object(forKey: NSLocale.Key.usesMetricSystem) as? Bool) ?? true
    }
}
