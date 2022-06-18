//
//  ImagePopUp.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/17/22.
//

/*
 a view to show full image in a neat window that is zoomable
 */

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
            
            // pin image sides to nearly the end of any screen size
            .frame(width: UIScreen.screenWidth, height: ((UIScreen.screenWidth) * image.size.height * 0.1)/(image.size.width * 0.1))
            .cornerRadius(30)
            .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(Color(UIColor.secondarySystemBackground), lineWidth: 6)
                )
            Button {
                showingImage.toggle()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .regular))
                    .padding(10)
                    .foregroundColor(.white)
            }
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .offset(x: (UIScreen.screenWidth) / 2 - 30, y: -(((UIScreen.screenWidth) * image.size.height * 0.1)/(image.size.width * 0.1) / 2) + 30)
        }
    }
}
