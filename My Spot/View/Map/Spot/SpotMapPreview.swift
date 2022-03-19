//
//  SpotMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/1/22.
//

import SwiftUI
import MapKit

struct SpotMapPreview: View {
    
    let spot: Spot
    @State private var scope:String = "Private"
    @State private var tags: [String] = []
    @State private var pad:CGFloat = 20
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                displayImage
                VStack {
                    HStack {
                        Image(systemName: "mappin")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(spot.locationName ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "globe")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(scope)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    Spacer()
                    HStack {
                        Text(spot.name ?? "")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Text("By: \(spot.founder ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(spot.date ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, pad)
                    if (!(spot.tags?.isEmpty ?? true)) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12, weight: .regular))
                                        .lineLimit(2)
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(.tint)
                                        .cornerRadius(5)
                                }
                            }
                        }
                        .padding(.bottom, 20)
                        .onAppear {
                            pad = 2
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            tags = spot.tags?.components(separatedBy: ", ") ?? []
            if (spot.isPublic) {
                scope = "Public"
            } else {
                scope = "Private"
            }
        }
    }
    
    private var displayImage: some View {
        ZStack {
            Image(uiImage: (spot.image ?? UIImage(systemName: "exclamationmark.triangle"))!)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .clipShape(RoundedRectangle(cornerRadius: 40))
            Color.black.opacity(0.5)
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .cornerRadius(40)
        }
    }
}
