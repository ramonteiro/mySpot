//
//  SetUpNewSpotNotification.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/29/22.
//

import SwiftUI
import MapKit
import Combine

struct SetUpNewSpotNotification: View {
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var centerRegion = MKCoordinateRegion()
    @State private var isSaving: Bool = false
    @Binding var newPlace: Bool
    @Binding var unableToAddSpot: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                NewSpotNotificationMapView(centerRegion: $centerRegion)
                    .allowsHitTesting(!isSaving)
                pinOverlayShape
                if isSaving {
                    savingSpinner
                }
            }
            .onAppear {
                setCenterRegion()
            }
            .interactiveDismissDisabled()
            .ignoresSafeArea()
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    saveButton
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    radiusOverlay
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    cancelButton
                }
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var savingSpinner: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            ProgressView("Saving".localized())
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                }
        }
    }
    
    private var radiusOverlay: some View {
        VStack {
            Text("Radius: 10 Miles".localized())
                .foregroundColor(.white)
                .padding([.leading,.trailing])
                .padding(.vertical, 2)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.gray)
                        .opacity(0.5)
                }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel".localized(), role: .destructive) {
            presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving)
    }
    
    private var saveButton: some View {
        Button("Save".localized()) {
            Task {
                await saveNewLocation()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(isSaving)
    }
    
    private var pinOverlayShape: some View {
        ZStack {
            VStack {
                MapPin()
                    .frame(width: 40, height: 40)
                    .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                Spacer()
                    .frame(height: 50)
            }
            CustomMapCircle()
                .stroke(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
        }
    }
    
    // MARK: - Functions
    
    private func setCenterRegion() {
        if (UserDefaults.standard.valueExists(forKey: "discovernotiy")) {
            let y = UserDefaults.standard.double(forKey: "discovernotiy")
            let x = UserDefaults.standard.double(forKey: "discovernotix")
            let location = CLLocationCoordinate2D(latitude: x, longitude: y)
            let newRegion = MKCoordinateRegion(center: location, span: mapViewModel.region.span)
            centerRegion = newRegion
        } else {
            centerRegion = mapViewModel.region
        }
    }
    
    private func saveNewLocation() async {
        let location = CLLocation(latitude: centerRegion.center.latitude, longitude: centerRegion.center.longitude)
        isSaving = true
        var placeName: String = ""
        mapViewModel.getPlacmarkOfLocation(location: location, isPrecise: false) { l in
            placeName = l
        }
        
        // check permissions
        await cloudViewModel.checkNotificationPermission()
        if cloudViewModel.notiPermission == 0 { // not determined
            // ask
            await cloudViewModel.requestPermissionNoti()
        }
        if cloudViewModel.notiPermission == 2 ||  cloudViewModel.notiPermission == 3 { // allowed
            
            // sub
            do {
                try await cloudViewModel.subscribeToNewSpot(fixedLocation: location)
                UserDefaults.standard.set(placeName, forKey: "discovernotiname")
                newPlace.toggle()
                UserDefaults.standard.set(Double(centerRegion.center.latitude), forKey: "discovernotix")
                UserDefaults.standard.set(Double(centerRegion.center.longitude), forKey: "discovernotiy")
            } catch { // no connection
                unableToAddSpot = 1
            }
        } else { // not allowed
            unableToAddSpot = 2
        }
        isSaving = false
        presentationMode.wrappedValue.dismiss()
    }
}
