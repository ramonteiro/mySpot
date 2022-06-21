//
//  WidgetHeader.swift
//  MySpotWidgetExtension
//
//  Created by Isaac Paschall on 6/20/22.
//

import SwiftUI

struct WidgetHeader: View {
    
    let locationName: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            if !locationName.isEmpty {
                Text(locationName)
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .padding(.leading, 15)
            } else {
                Text("Near Your Location".localized())
                    .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .padding(.leading, 15)
            }
            Spacer()
            Image(uiImage: UIImage(named: "logo.png")!)
                .resizable()
                .frame(width: 20, height: 20)
                .scaledToFit()
                .padding(.trailing, 15)
        }
    }
}
