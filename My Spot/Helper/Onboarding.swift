//
//  Onboarding.swift
//  My Spot
//
//  Created by Isaac Paschall on 4/3/22.
//

import SwiftUI

struct Onboarding: View {
    @State private var stage = [0,1,2,3]
    var body: some View {
        TabView(selection: $stage) {
            ForEach(stage.indices, id: \.self) { i in
                onBoardPage(i: i)
            }
        }
        .tabViewStyle(.page)
    }
}

struct onBoardPage: View {
    var i: Int
    var body: some View {
        if (i == 0) {
            
        } else if (i == 1) {
            
        } else if (i == 2) {
            
        } else if (i == 3) {
            
        }
    }
}

