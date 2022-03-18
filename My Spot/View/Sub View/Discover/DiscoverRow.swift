//
//  DiscoverRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 DiscoverRow:
 view for each spot from db item in list in root view
 */

import SwiftUI

struct DiscoverRow: View {
    var spot: SpotFromCloud
    @State private var tags: [String] = []

    var body: some View {
        HStack {
            if let url = spot.imageURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .cornerRadius(20)
                    .shadow(color: .black, radius: 5)
            } else {
                ProgressView("Loading Image")
                    .frame(width: 100, height: 120, alignment: .center)
                    .cornerRadius(20)
            }
            
            VStack(alignment: .leading) {
                Text("\(spot.name)\(spot.emoji)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                Text("By: \(spot.founder)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                
                Text("\(spot.date)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                
                HStack(alignment: .center) {
                    Image(systemName: "heart.fill")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                    Text("\(spot.likes)")
                        .font(.subheadline)
                        .foregroundColor(Color.gray)
                }
                
                HStack(alignment: .center) {
                    Image(systemName: "mappin")
                        .foregroundColor(Color.gray)
                        .font(.subheadline)
                    Text(spot.locationName)
                        .foregroundColor(Color.gray)
                        .font(.subheadline)
                }
                
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
                }
            }
            .padding(.leading, 5)
        }
        .onAppear {
            tags = spot.type.components(separatedBy: ", ")
        }
    }
}
