//
//  BadgeViewOverlay.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct Badge: View {
    @Binding var count: Int
    let color: Color

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(count))
                .font(.system(size: 16))
                .padding(5)
                .background(color)
                .clipShape(Circle())
                .alignmentGuide(.top) { $0[.bottom] - $0.height * 0.45 }
                .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.15 }
        }
    }
}
