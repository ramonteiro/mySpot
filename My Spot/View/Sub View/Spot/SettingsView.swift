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
    @State private var message = "Message to My Spot developer: ".localized()
    @State private var discoverNoti = false
    @State private var discoverProcess = false
    @State private var unableToAddSpot = 0 // 0: ok, 1: no connection, 2: no permission
    @State private var showingErrorNoPermission = false
    @State private var showingErrorNoConnection = false
    @State private var preventDoubleTrigger = false // stops onchange from triggering itself
    @State private var limits: Double = 10
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(cloudViewModel.systemColorArray.indices, id: \.self) { i in
                                if i != cloudViewModel.systemColorArray.count - 1 {
                                    Circle()
                                        .strokeBorder(cloudViewModel.systemColorIndex == i ? (colorScheme == .dark ? .white : .black) : .clear, lineWidth: 5)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().foregroundColor(cloudViewModel.systemColorArray[i]))
                                        .onTapGesture {
                                            cloudViewModel.systemColorIndex = i
                                            UserDefaults.standard.set(i, forKey: "systemcolor")
                                        }
                                } else {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(cloudViewModel.systemColorIndex == i ? (colorScheme == .dark ? .white : .black) : .clear, lineWidth: 5)
                                            .frame(width: 40, height: 40)
                                            .background(Circle().foregroundColor(cloudViewModel.systemColorArray[i]))
                                            .onTapGesture {
                                                cloudViewModel.systemColorIndex = i
                                                UserDefaults.standard.set(i, forKey: "systemcolor")
                                            }
                                        Image(systemName: "pencil")
                                            .frame(width: 40, height: 40)
                                    }
                                }
                            }
                        }
                    }
                    if (cloudViewModel.systemColorIndex == cloudViewModel.systemColorArray.count - 1) {
                        ColorPicker(selection: $cloudViewModel.systemColorArray[cloudViewModel.systemColorArray.count - 1], supportsOpacity: false) {
                            Text("Edit Custom Color".localized())
                        }
                    }
                } header: {
                    Text("Color Scheme".localized())
                        .font(.headline)
                }
                Section {
                    Toggle(isOn: $discoverNoti) {
                        Text("New Spots Notification".localized())
                    }
                    .disabled(discoverProcess)
                    .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    if (cloudViewModel.notiNewSpotOn) {
                        Button {
                            showingConfigure.toggle()
                        } label: {
                            Text("Configure".localized())
                                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                                .disabled(discoverProcess)
                        }
                    }
                    
                } header: {
                    if (cloudViewModel.notiNewSpotOn && !placeName.isEmpty) {
                        Text("Area Set To: ".localized() + (placeName))
                    }
                } footer: {
                    Text("Alerts when new spots are added to your location, within a 10 mile radius. Tap 'Configure' to change the location where new spots should alert you.".localized())
                }
                Section {
                    Slider(value: $limits, in: 1...30, step: 1) { didChange in
                        if didChange {
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                } header: {
                    Text("Max Spots To Load: ".localized() + String(Int(limits)))
                } footer: {
                    Text("Set how many spots to load at once. If load times are slow, lower this number.".localized())
                }
                Section {
                    Button {
                        showingMailSheet = true
                    } label: {
                        Text("Email Developer".localized())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                } header: {
                    Text("Help".localized())
                        .font(.headline)
                } footer: {
                    Text("Ask questions, submit bugs, or suggest new features. All comments are welcomed and I will read every email sent!".localized())
                }
                Section {
                    Button {
                        let youtubeId = "UcQJhaeTPng"
                        var youtubeUrl = URL(string:"youtube://\(youtubeId)")!
                        if UIApplication.shared.canOpenURL(youtubeUrl){
                            UIApplication.shared.open(youtubeUrl)
                        } else{
                            youtubeUrl = URL(string:"https://www.youtube.com/watch?v=\(youtubeId)")!
                            UIApplication.shared.open(youtubeUrl)
                        }
                    } label: {
                        Text("Video Tutorial".localized())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                } footer: {
                    Text("Youtube video with timestamps to demonstrate how to use My Spot.".localized())
                }
                Section {
                    Button {
                        if let url = URL(string:"https://wp.me/PdMUcQ-7") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("About Me".localized())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                } footer: {
                    Text("A link to my wordpress site with short detail about me and the current privacy policy in My Spot.".localized())
                }
            }
            .onChange(of: discoverNoti) { newValue in
                if newValue && !preventDoubleTrigger {
                    Task {
                        discoverProcess = true
                        await cloudViewModel.checkNotificationPermission()
                        if cloudViewModel.notiPermission == 0 { // not determined
                            // ask
                            await cloudViewModel.requestPermissionNoti()
                        }
                        if cloudViewModel.notiPermission == 2 ||  cloudViewModel.notiPermission == 3 { // allowed/provisional
                            // subscribe
                            var location = CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)
                            if (UserDefaults.standard.valueExists(forKey: "discovernotix")) {
                                location = CLLocation(latitude: UserDefaults.standard.double(forKey: "discovernotix"), longitude: UserDefaults.standard.double(forKey: "discovernotiy"))
                            } else {
                                UserDefaults.standard.set(Double(mapViewModel.region.center.latitude), forKey: "discovernotix")
                                UserDefaults.standard.set(Double(mapViewModel.region.center.longitude), forKey: "discovernotiy")
                            }
                            do {
                                try await cloudViewModel.subscribeToNewSpot(fixedLocation: location)
                                cloudViewModel.notiNewSpotOn = true
                                UserDefaults.standard.set(true, forKey: "discovernot")
                            } catch {
                                // alert error connecting
                                cloudViewModel.notiNewSpotOn = false
                                UserDefaults.standard.set(false, forKey: "discovernot")
                                preventDoubleTrigger = true
                                discoverNoti = false
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                                showingErrorNoConnection = true
                            }
                        } else { // denied/unknown
                            // alert, notifications do not have permission
                            cloudViewModel.notiNewSpotOn = false
                            UserDefaults.standard.set(false, forKey: "discovernot")
                            preventDoubleTrigger = true
                            discoverNoti = false
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.warning)
                            showingErrorNoPermission = true
                        }
                        discoverProcess = false
                    }
                }
                if !newValue && !preventDoubleTrigger {
                    // unsubscribe
                    Task {
                        discoverProcess = true
                        do {
                            try await cloudViewModel.unsubscribeAll()
                            cloudViewModel.notiNewSpotOn = false
                            UserDefaults.standard.set(false, forKey: "discovernot")
                        } catch {
                            // alert no connection
                            preventDoubleTrigger = true
                            discoverNoti = true
                            cloudViewModel.notiNewSpotOn = true
                            UserDefaults.standard.set(true, forKey: "discovernot")
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.warning)
                            showingErrorNoConnection = true
                        }
                        discoverProcess = false
                    }
                }
                if preventDoubleTrigger {
                    preventDoubleTrigger = false
                }
            }
            .onChange(of: limits) { newValue in
                UserDefaults.standard.set(Int(limits), forKey: "limit")
                cloudViewModel.limit = Int(limits)
            }
            .alert("Notification Permissions Denied".localized(), isPresented: $showingErrorNoPermission) {
                Button("Settings".localized()) {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                Button("Cancel".localized(), role: .cancel) { }
            } message: {
                Text("Please check settings and make sure notifications are on for My Spot.".localized())
            }
            .alert("Connection Error".localized(), isPresented: $showingErrorNoConnection) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text("Please check internet connection and try again.".localized())
            }
            .onAppear {
                if UserDefaults.standard.valueExists(forKey: "discovernotiname") {
                    placeName = UserDefaults.standard.string(forKey: "discovernotiname") ?? ""
                } else {
                    mapViewModel.getPlacmarkOfLocationLessPrecise(location: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude)) { place in
                        placeName = place
                    }
                }
                limits = Double(cloudViewModel.limit)
            }
            .fullScreenCover(isPresented: $showingConfigure, onDismiss: {
                if unableToAddSpot == 2 {
                    unableToAddSpot = 0
                    cloudViewModel.notiNewSpotOn = false
                    UserDefaults.standard.set(false, forKey: "discovernot")
                    preventDoubleTrigger = true
                    discoverNoti = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showingErrorNoPermission = true
                } else if unableToAddSpot == 1 {
                    unableToAddSpot = 0
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showingErrorNoConnection = true
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
            .onChange(of: newPlace) { newValue in
                placeName = UserDefaults.standard.string(forKey: "discovernotiname") ?? ""
            }
            .onChange(of: cloudViewModel.systemColorArray[cloudViewModel.systemColorArray.count - 1]) { newColor in
                let color = UIColor(newColor)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0

                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                UserDefaults.standard.set(Double(red), forKey: "customColorR")
                UserDefaults.standard.set(Double(green), forKey: "customColorG")
                UserDefaults.standard.set(Double(blue), forKey: "customColorB")
                UserDefaults.standard.set(Double(alpha), forKey: "customColorA")
            }
            .navigationTitle("Settings".localized())
            .navigationViewStyle(.stack)
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Done".localized())
                            .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                    }
                }
            }
        }
        .onAppear {
            if cloudViewModel.notiNewSpotOn ==  true {
                preventDoubleTrigger = true
            }
            discoverNoti = cloudViewModel.notiNewSpotOn
        }
    }
}
