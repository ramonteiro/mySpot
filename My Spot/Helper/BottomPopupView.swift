//
//  BottomPopupView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/17/22.
//

/*
a view that pops up on bottom of screen to prompt user to enter a new name after attempting to save a public spot
 */

import SwiftUI
import Combine

struct NamePopupView: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @Binding var isPresented: Bool
    @Binding var text: String
    @Binding var saved: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Enter Spot Name")
                    .font(.system(size: 25, weight: .bold, design: .default))
                Spacer()
                Button {
                    text = ""
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .imageScale(.small)
                        .frame(width: 32, height: 32)
                        .background(.gray.opacity(0.5))
                        .cornerRadius(16)
                        .foregroundColor(.white)
                }
            }
            TextField("", text: $text)
                .frame(height: 36)
                .padding([.leading, .trailing], 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)
                .submitLabel(.done)
                .onReceive(Just(text)) { _ in
                    if (text.count > MaxCharLength.names) {
                        text = String(text.prefix(MaxCharLength.names))
                    }
                }
                .onSubmit {
                    if (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                        saved = true
                    } else {
                        text = ""
                    }
                    isPresented = false
                }
            HStack {
                Spacer()
                Button {
                    saved = true
                    isPresented = false
                } label: {
                    Text("Save")
                }
                .frame(width: 80, height: 36)
                .background(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}


struct BottomPopupView<Content: View>: View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                content
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(radius: 16, corners: [.topLeft, .topRight])
            }
            .edgesIgnoringSafeArea([.bottom])
        }
        .transition(.move(edge: .bottom))
    }
}

struct RoundedCornersShape: Shape {
    
    let radius: CGFloat
    let corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    
    func cornerRadius(radius: CGFloat, corners: UIRectCorner = .allCorners) -> some View {
        clipShape(RoundedCornersShape(radius: radius, corners: corners))
    }
}

struct OverlayModifier<OverlayView: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let overlayView: OverlayView
    
    init(isPresented: Binding<Bool>, @ViewBuilder overlayView: @escaping () -> OverlayView) {
        self._isPresented = isPresented
        self.overlayView = overlayView()
    }
    
    func body(content: Content) -> some View {
        content.overlay(isPresented ? overlayView : nil)
    }
}

extension View {
    
    func popup<OverlayView: View>(isPresented: Binding<Bool>,
                                  blurRadius: CGFloat = 3,
                                  blurAnimation: Animation? = .linear,
                                  @ViewBuilder overlayView: @escaping () -> OverlayView) -> some View {
        return blur(radius: isPresented.wrappedValue ? blurRadius : 0)
            .allowsHitTesting(!isPresented.wrappedValue)
            .modifier(OverlayModifier(isPresented: isPresented, overlayView: overlayView))
    }
}
