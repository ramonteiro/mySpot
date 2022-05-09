//
//  RowView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct RowView: View {
    @ObservedObject var mapViewModel: WatchLocationManager
    let spot: Spot
    @State private var away = ""
    
    var body: some View {
        HStack(spacing: 5) {
            Image(uiImage: (UIImage(data: spot.image) ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .cornerRadius(10)
            VStack {
                HStack {
                    Text(spot.name)
                        .font(.system(size: 16))
                        .lineLimit(2)
                    Spacer()
                }
                HStack {
                    Text(away + " away".localized())
                        .font(.system(size: 12))
                        .lineLimit(1)
                    Spacer()
                }
            }
            .frame(width: WKInterfaceDevice.current().screenBounds.size.width * 0.5)
        }
        .onAppear {
            away = calculateDistance(x: spot.x, y: spot.y)
        }
    }
    
    private func calculateDistance(x: Double, y: Double) -> String {
        guard let userLocation = mapViewModel.locationManager?.location else { return "" }
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
