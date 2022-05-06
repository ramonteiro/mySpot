//
//  NotificationView.swift
//  MySpotWatch WatchKit Extension
//
//  Created by Isaac Paschall on 5/6/22.
//

import SwiftUI

struct NotificationView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: UIImage(named: "logo.png")!)
                .resizable()
                .frame(width: 80, height: 80)
            Text("A new spot was added to your area!".localized())
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}
