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
            away = mapViewModel.calculateDistance(x: spot.x, y: spot.y)
        }
    }
}
