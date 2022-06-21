//
//  TimeLineProvider.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import WidgetKit
import UIKit

struct Provider: TimelineProvider {
    
    var cloudViewModel: CloudKitViewModel
    var mapViewModel: WidgetLocationManager
    let emptySpot = SpotEntry(locationName: "Coconino County",userx: 33.71447172967623, usery: -112.29073153451222, isNoLocation: false, spot: [
        Spot(spotid: "", name: "Antelope Canyon", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "atelopeCanyon")?.jpegData(compressionQuality: 0.9))!, x: 36.8619, y: -111.3743),
        Spot(spotid: "", name: "South Rim Trail", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "southRim")?.jpegData(compressionQuality: 0.9))!, x: 36.056198, y: -112.125198),
        Spot(spotid: "", name: "Havasu Falls", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "havasuFalls")?.jpegData(compressionQuality: 0.9))!, x: 36.2552, y: -112.6979),
        Spot(spotid: "", name: "Fire Point", customLocation: false, locationName: "Grand Canyon", image: (UIImage(named: "firePoint")?.jpegData(compressionQuality: 0.9))!, x: 36.3558152, y: -112.3615679)
    ])
    
    func placeholder(in context: Context) -> SpotEntry {
        let entry = emptySpot
        return entry
    }
    
    let noLocationPlaceholder = SpotEntry(locationName: "", userx: 0.0, usery: 0.0, isNoLocation: true, spot: [])
    
    func getSnapshot(in context: Context, completion: @escaping (SpotEntry) -> Void) {
        if context.isPreview {
            completion(emptySpot)
        } else {
            if mapViewModel.locationManager!.isAuthorizedForWidgetUpdates {
                mapViewModel.fetchLocation { location in
                    mapViewModel.getPlacmarkOfLocation(location: location) { locationName in
                        cloudViewModel.fetchSpotPublic(userLocation: location, resultLimit: 4) { (result) in
                            switch result {
                            case .success(let entry):
                                completion(SpotEntry(locationName: locationName, userx: location.coordinate.latitude, usery: location.coordinate.longitude, isNoLocation: false, spot: entry))
                            case .failure(let error):
                                print("snapshot Error: \(error)")
                                completion(emptySpot)
                            }
                        }
                    }
                }
            } else {
                completion(noLocationPlaceholder)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SpotEntry>) -> Void) {
        if mapViewModel.locationManager!.isAuthorizedForWidgetUpdates {
            mapViewModel.fetchLocation { location in
                mapViewModel.getPlacmarkOfLocation(location: location) { locationName in
                    cloudViewModel.fetchSpotPublic(userLocation: location, resultLimit: 4) { (result) in
                        switch result {
                        case .success(let entry):
                            let entry = SpotEntry(locationName: locationName, userx: location.coordinate.latitude, usery: location.coordinate.longitude, isNoLocation: false, spot: entry)
                            let timeline = Timeline(entries: [entry], policy: .never)
                            completion(timeline)
                        case .failure(let error):
                            print("TimeLine Error: \(error)")
                            let timeline = Timeline(entries: [emptySpot], policy: .after(Date().addingTimeInterval(60 * 2)))
                            completion(timeline)
                        }
                    }
                }
            }
        } else {
            let timeline = Timeline(entries: [noLocationPlaceholder], policy: .after(Date().addingTimeInterval(10)))
            completion(timeline)
        }
    }
}
