//
//  SettingsView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/29/22.
//

import SwiftUI
import CoreLocation

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingMailSheet = false
    @State private var showingConfigure = false
    @State private var placeName = ""
    @State private var newPlace = false
    @State private var message = "Message to My Spot developer: "
    @State private var showingCannotTurnOffNoti = false
    @State private var showingCannotTurnOnNoti = false
    @State private var unableToAddSpot = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(cloudViewModel.systemColorArray.indices, id: \.self) { i in
                                Circle()
                                    .strokeBorder(cloudViewModel.systemColorIndex == i ? (colorScheme == .dark ? .white : .black) : .clear, lineWidth: 5)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().foregroundColor(cloudViewModel.systemColorArray[i]))
                                    .onTapGesture {
                                        cloudViewModel.systemColorIndex = i
                                        UserDefaults.standard.set(i, forKey: "systemcolor")
                                    }
                            }
                        }
                    }
                } header: {
                    Text("Color Scheme")
                        .font(.headline)
                }
                Section {
                    Toggle(isOn: $cloudViewModel.notiPlaylistOn) {
                        Text("Shared Playlists")
                    }
                    .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                } header: {
                    Text("Notifications")
                        .font(.headline)
                } footer: {
                    Text("Alerts when new spots are added to shared playlists.")
                }
                Section {
                    Toggle(isOn: $cloudViewModel.notiNewSpotOn) {
                        Text("New Spots")
                    }
                    .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    if (cloudViewModel.notiNewSpotOn) {
                        Button {
                            showingConfigure.toggle()
                        } label: {
                            Text("Configure")
                                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                        }
                    }
                    
                } header: {
                    if (cloudViewModel.notiNewSpotOn && !placeName.isEmpty) {
                        Text("Area Set To: \(placeName)")
                    }
                } footer: {
                    Text("Alerts when new spots are added to around a location. Tap 'Configure' to set up the area where new spots should alert you.")
                }
                Section {
                    Button {
                        showingMailSheet = true
                    } label: {
                        Text("Email Developer")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                } header: {
                    Text("Help")
                        .font(.headline)
                } footer: {
                    Text("Ask questions, submit bugs, or suggest new features. All comments are welcomed and I will read every email sent!")
                }
                Section {
                    Button {
                        let youtubeId = "f-sQsR2YS4U"
                        var youtubeUrl = URL(string:"youtube://\(youtubeId)")!
                        if UIApplication.shared.canOpenURL(youtubeUrl){
                            UIApplication.shared.open(youtubeUrl)
                        } else{
                            youtubeUrl = URL(string:"https://www.youtube.com/watch?v=\(youtubeId)")!
                            UIApplication.shared.open(youtubeUrl)
                        }
                    } label: {
                        Text("Video Tutorial")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                } footer: {
                    Text("Youtube video with timestamps to demonstrate how to use My Spot.")
                }
            }
            .fullScreenCover(isPresented: $showingConfigure, onDismiss: {
                if unableToAddSpot {
                    unableToAddSpot = false
                    showingCannotTurnOnNoti = true
                }
            }) {
                SetUpNewSpotNoti(newPlace: $newPlace, unableToAddSpot: $unableToAddSpot)
                    .accentColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            }
            .sheet(isPresented: $showingMailSheet) {
                MailView(message: $message) { returnedMail in
                    print(returnedMail)
                }
                .accentColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            }
            .alert("Unable to save notification. Please check internet and try again.", isPresented: $showingCannotTurnOnNoti) {
                Button("OK", role: .cancel) { }
            }
            .alert("Unable to turn off notification at the moment. Please check internet and try again.", isPresented: $showingCannotTurnOffNoti) {
                Button("OK", role: .cancel) { }
            }
            .alert("Please Enable Notifications In Settings.", isPresented: $cloudViewModel.askForPermission) {
                Button("OK", role: .cancel) { }
            }
            .onChange(of: cloudViewModel.notiNewSpotOn) { newValue in
                if cloudViewModel.doNotAlert {
                    cloudViewModel.doNotAlert = false
                } else {
                    if newValue {
                        if (UserDefaults.standard.valueExists(forKey: "discovernotix")) {
                            Task {
                                await cloudViewModel.subscribeToNoti(notiType: 2, fixedLocation: CLLocation(latitude: UserDefaults.standard.double(forKey: "discovernotix"), longitude: UserDefaults.standard.double(forKey: "discovernotiy")), radiusInKm: UserDefaults.standard.double(forKey: "discovernotikm"))
                                if (cloudViewModel.notiDenied) {
                                    cloudViewModel.notiDenied = false
                                    cloudViewModel.notiNewSpotOn = false
                                    showingCannotTurnOnNoti = true
                                }
                            }
                        } else {
                            Task {
                                await cloudViewModel.subscribeToNoti(notiType: 2, fixedLocation: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), radiusInKm: 1000)
                                if (cloudViewModel.notiDenied) {
                                    cloudViewModel.notiDenied = false
                                    cloudViewModel.notiNewSpotOn = false
                                    showingCannotTurnOnNoti = true
                                } else {
                                    UserDefaults.standard.set(Double(mapViewModel.region.center.latitude), forKey: "discovernotix")
                                    UserDefaults.standard.set(Double(mapViewModel.region.center.longitude), forKey: "discovernotiy")
                                    UserDefaults.standard.set(Double(1000), forKey: "discovernotikm")
                                }
                            }
                        }
                    } else {
                        Task {
                            do {
                                try await cloudViewModel.unsubscribe(id: "NewSpotDiscover")
                            } catch {
                                cloudViewModel.doNotAlert = true
                                cloudViewModel.notiNewSpotOn = true
                                showingCannotTurnOffNoti = true
                            }
                        }
                    }
                }
            }
            .onChange(of: cloudViewModel.notiPlaylistOn) { newValue in
                
            }
            .onChange(of: cloudViewModel.notiNewSpotOn) { newValue in
                UserDefaults.standard.set(newValue, forKey: "discovernot")
            }
            .onChange(of: cloudViewModel.notiPlaylistOn) { newValue in
                UserDefaults.standard.set(newValue, forKey: "playlistnot")
            }
            .onAppear {
                if UserDefaults.standard.valueExists(forKey: "discovernotiname") {
                    placeName = UserDefaults.standard.string(forKey: "discovernotiname") ?? ""
                }
            }
            .onChange(of: newPlace) { newValue in
                placeName = UserDefaults.standard.string(forKey: "discovernotiname") ?? ""
            }
            .navigationTitle("Settings")
            .navigationViewStyle(.stack)
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done")
                            .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    }
                }
            }
        }
    }
}
