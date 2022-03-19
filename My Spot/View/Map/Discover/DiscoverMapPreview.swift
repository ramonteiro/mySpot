//
//  DiscoverMapPreview.swift
//  mySpot
//
//  Created by Isaac Paschall on 3/2/22.
//

import SwiftUI
import MapKit

struct DiscoverMapPreview: View {
    
    let spot: SpotFromCloud
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
                        Text(spot.locationName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("\(spot.likes)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top)
                    Spacer()
                    HStack {
                        Text(spot.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    HStack {
                        Text("By: \(spot.founder)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(spot.date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, pad)
                    if (!(spot.type.isEmpty)) {
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
            tags = spot.type.components(separatedBy: ", ")
        }
    }
    
    private var displayImage: some View {
        ZStack {
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
            }
            Color.black.opacity(0.5)
                .frame(width: UIScreen.screenWidth - 20, height: UIScreen.screenHeight * 0.25)
                .cornerRadius(40)
        }
    }
}
