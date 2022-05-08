//
//  RowView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct RowView: View {
    let spot: Spot
    
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
                if !spot.locationName.isEmpty {
                    HStack {
                        Image(systemName: (!spot.customLocation ? "mappin" : "figure.wave"))
                            .font(.system(size: 12))
                        Text(spot.locationName)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                    }
                }
            }
            .frame(width: WKInterfaceDevice.current().screenBounds.size.width * 0.5)
        }
    }
}
