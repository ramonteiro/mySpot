//
//  CustomCoordinatesSheet.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/18/22.
//

import SwiftUI
import MapKit

struct CustomCoordinatesSheet: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var customCoordinates: CLLocationCoordinate2D
    @Binding var didSet: Bool
    @State private var xString: String = ""
    @State private var yString: String = ""
    @State private var errorMessage: String = ""
    
    var body: some View {
        Form {
            latitudeAndLongitudeTextBox
            searchButton
        }
        .gesture(DragGesture()
            .onChanged { _ in
                UIApplication.shared.dismissKeyboard()
            }
        )
    }
    
    private var latitudeAndLongitudeTextBox: some View {
        Section {
            TextField("Latitude(X)".localized(), text: $xString)
                .keyboardType(.numberPad)
            TextField("Longitude(Y)".localized(), text: $yString)
                .keyboardType(.numberPad)
        } header: {
            Text("Enter Coordinates".localized())
        } footer: {
            Text(errorMessage)
        }
    }
    
    private var searchButton: some View {
        Button {
            if CLLocationCoordinate2DIsValid(CLLocationCoordinate2D(latitude: CLLocationDegrees(Float(xString) ?? 0.0),
                                                                    longitude: CLLocationDegrees(Float(yString) ?? 0.0))) {
                didSet = true
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = "Invalid Coordinates!".localized()
            }
        } label: {
            Text("Search".localized())
        }
    }
}
