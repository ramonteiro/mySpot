//
//  ImagePopUp.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/17/22.
//

import SwiftUI

struct ImagePopUp: View {
    
    @Binding var showingImage: Bool
    var image: UIImage
    var body: some View {
        ZStack {
            ZoomableScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .frame(width: UIScreen.screenWidth - 50, height: ((UIScreen.screenWidth - 50) * image.size.height * 0.1)/(image.size.width * 0.1))
            .cornerRadius(30)
            .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(UIColor.secondarySystemBackground), lineWidth: 6)
                )
            Button {
                showingImage.toggle()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .regular))
                    .padding(5)
                    .foregroundColor(.white)
            }
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .offset(x: (UIScreen.screenWidth - 50) / 2 - 30, y: -(((UIScreen.screenWidth - 50) * image.size.height * 0.1)/(image.size.width * 0.1) / 2) + 30)
        }
    }
}
