//
//  DescriptionView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/7/22.
//

import SwiftUI

struct DescriptionView: View {
    let description: String
    
    var body: some View {
        Text(description)
            .multilineTextAlignment(.leading)
    }
}
