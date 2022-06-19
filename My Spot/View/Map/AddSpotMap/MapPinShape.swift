//
//  MapPinShape.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI

struct MapPin: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { path in
            path.move(to: CGPoint(x: rect.midX,
                                  y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.midX,
                                          y: rect.minY),
                              control: CGPoint(x: rect.minX,
                                               y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.midX,
                                          y: rect.maxY),
                              control: CGPoint(x: rect.maxX,
                                               y: rect.minY))
        }
    }
}
