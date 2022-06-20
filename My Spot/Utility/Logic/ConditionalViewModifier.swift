//
//  ConditionalViewModifier.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

extension View {

    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
