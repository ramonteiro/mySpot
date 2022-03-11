//
//  SpotRow.swift
//  mySpot
//
//  Created by Isaac Paschall on 2/28/22.
//

/*
 SpotRow:
 view for each spot from db item in list in root view of my spots
 */

import SwiftUI

struct SpotRow: View {
    @ObservedObject var spot: Spot

    var body: some View {
        if (checkIfItemExist()) {
            if (spot.isPublic) {
                displayGreenCircleImage
            } else {
                displayRedCircleImage
            }
        }
    }
    
    private func checkIfItemExist() -> Bool {
        if let _ = spot.name {
            return true
        } else {
            return false
        }
    }
    
    private var displayRedCircleImage: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(spot.name ?? "")
                Text("By: \(spot.founder ?? "")").font(.subheadline).foregroundColor(.gray)
                Text("On: \(spot.date ?? "")").font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Image(uiImage: spot.image!)
                .resizable()
                .clipShape(Circle())
                .frame(width: UIScreen.main.bounds.width * 0.16, height: UIScreen.main.bounds.height * (60/812), alignment: .center)
                .overlay(Circle().stroke(Color.red, lineWidth: 1))
             
        }
    }
    
    private var displayGreenCircleImage: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(spot.name ?? "")
                Text("By: \(spot.founder ?? "")").font(.subheadline).foregroundColor(.gray)
                Text("On: \(spot.date ?? "")").font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Image(uiImage: spot.image!)
                .resizable()
                .clipShape(Circle())
                .frame(width: UIScreen.main.bounds.width * 0.16, height: UIScreen.main.bounds.height * (60/812), alignment: .center)
                .overlay(Circle().stroke(Color.green, lineWidth: 1))
        }
    }
}
