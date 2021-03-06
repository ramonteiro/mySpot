//
//  MapViewModel.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import CoreLocation

class WatchLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    var locationManager: CLLocationManager?
    @Published var location = CLLocation(latitude: 0, longitude: 0)
    @Published var locationName = ""
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
    
    func calculateDistance(x: Double, y: Double) -> String {
        guard let userLocation = self.locationManager?.location else { return "" }
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
