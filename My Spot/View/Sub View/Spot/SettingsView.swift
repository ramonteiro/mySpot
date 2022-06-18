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
    @State private var showNotificationSheet = false
    @State private var newPlace = false
    @State private var message = "Message to My Spot developer: ".localized()
    @State private var discoverNoti = false
    @State private var sharedNoti = false
    @State private var discoverProcess = false
    @State private var unableToAddSpot = 0 // 0: ok, 1: no connection, 2: no permission
    @State private var showingErrorNoPermission = false
    @State private var showingErrorNoConnection = false
    @State private var preventDoubleTrigger = false // stops onchange from triggering itself
    @State private var preventDoubleTriggerShared = false
    @State private var limits: Double = 10
    @State private var showNotiView = false
    @State private var dateMemberSince = "?"
    let def = UserDefaults.standard
    
    var body: some View {
        NavigationView {
            formView
                .onChange(of: sharedNoti) { newValue in
                    triggerSharedNoti(newValue)
                }
                .onChange(of: discoverNoti) { newValue in
                    triggerDiscoverNoti(newValue)
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
                    }
                    limits = Double(cloudViewModel.limit)
                }
                .fullScreenCover(isPresented: $showingConfigure, onDismiss: {
                    checkForErrors()
                }) {
                    SetUpNewSpotNotification(newPlace: $newPlace, unableToAddSpot: $unableToAddSpot)
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
                    setNewColor(newColor)
                }
                .onChange(of: cloudViewModel.systemColorIndex) { index in
                    setNewColorFromIndex(index: index)
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
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            initializeVars()
        }
    }
    
    private var formView: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    colorWheel
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
                    Text("New Spots".localized())
                }
                .disabled(discoverProcess)
                .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
                if (cloudViewModel.notiNewSpotOn) {
                    Button {
                        showingConfigure.toggle()
                    } label: {
                        Text("Configure".localized())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .disabled(discoverProcess)
                    }
                }
            } header: {
                VStack(spacing: 0) {
                    Text("Notifications".localized())
                        .font(.headline)
                    if (cloudViewModel.notiNewSpotOn && !placeName.isEmpty) {
                        Text("Area Set To: ".localized() + (placeName))
                            .padding(.top)
                    }
                }
            } footer: {
                Text("Alerts when new spots are added to your location, within a 10 mile radius. Tap 'Configure' to change the location where new spots should alert you.".localized())
            }
            Section {
                Toggle(isOn: $sharedNoti) {
                    Text("Shared Playlists".localized())
                }
                .disabled(discoverProcess)
                .tint(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            } footer: {
                Text("Alerts when a shared playlist is modified.".localized())
            }
            Section {
                Slider(value: $limits, in: 1...30, step: 1) { didChange in
                    if didChange {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
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
                    if let url = URL(string:"https://www.tiktok.com/@myspotexploration") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Tiktok")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            } footer: {
                Text("Follow me on".localized() + " Tiktok!")
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
                if let date = UserDefaults.standard.object(forKey: "accountdate") as? Date {
                    Text("A link to my wordpress site with short detail about me and the current privacy policy in My Spot.".localized() + "\n\n\nMy Spot v 2.0.1" + "\n" + "Member Since".localized() + ": \(dateMemberSince)")
                        .onAppear {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "MMM d, yyyy"
                            dateMemberSince = dateFormatter.string(from: date)
                        }
                } else {
                    Text("A link to my wordpress site with short detail about me and the current privacy policy in My Spot.".localized() + "\n\n\nMy Spot v 2.0")
                }
            }
        }
    }
    
    private var colorWheel: some View {
        HStack {
            ForEach(cloudViewModel.systemColorArray.indices, id: \.self) { i in
                if i != cloudViewModel.systemColorArray.count - 1 {
                    Circle()
                        .strokeBorder(cloudViewModel.systemColorIndex == i ? (colorScheme == .dark ? .white : .black) : .clear, lineWidth: 5)
                        .frame(width: 40, height: 40)
                        .background(Circle().foregroundColor(cloudViewModel.systemColorArray[i]))
                        .onTapGesture {
                            cloudViewModel.systemColorIndex = i
                        }
                } else {
                    ZStack {
                        Circle()
                            .strokeBorder(cloudViewModel.systemColorIndex == i ? (colorScheme == .dark ? .white : .black) : .clear, lineWidth: 5)
                            .frame(width: 40, height: 40)
                            .background(Circle().foregroundColor(cloudViewModel.systemColorArray[i]))
                            .onTapGesture {
                                cloudViewModel.systemColorIndex = i
                                UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(i, forKey: "colorIndex")
                            }
                        Image(systemName: "pencil")
                            .frame(width: 40, height: 40)
                    }
                }
            }
        }
    }
    
    private func triggerSharedNoti(_ newValue: Bool) {
        if newValue && !preventDoubleTriggerShared {
            Task {
                discoverProcess = true
                await cloudViewModel.checkNotificationPermission()
                if cloudViewModel.notiPermission == 0 { // not determined
                    // ask
                    await cloudViewModel.requestPermissionNoti()
                }
                if cloudViewModel.notiPermission == 2 ||  cloudViewModel.notiPermission == 3 { // allowed/provisional
                    // subscribe
                    do {
                        try await cloudViewModel.subscribeToShares()
                        cloudViewModel.notiSharedOn = true
                        UserDefaults.standard.set(true, forKey: "sharednot")
                    } catch {
                        // alert error connecting
                        cloudViewModel.notiSharedOn = false
                        UserDefaults.standard.set(false, forKey: "sharednot")
                        preventDoubleTriggerShared = true
                        sharedNoti = false
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        showingErrorNoConnection = true
                    }
                } else { // denied/unknown
                    // alert, notifications do not have permission
                    cloudViewModel.notiSharedOn = false
                    UserDefaults.standard.set(false, forKey: "sharednot")
                    preventDoubleTriggerShared = true
                    sharedNoti = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showingErrorNoPermission = true
                }
                discoverProcess = false
            }
        }
        if !newValue && !preventDoubleTriggerShared {
            // unsubscribe
            Task {
                discoverProcess = true
                do {
                    try await cloudViewModel.unsubscribeAllShared()
                    try await cloudViewModel.unsubscribeAllPrivate()
                    cloudViewModel.notiSharedOn = false
                    UserDefaults.standard.set(false, forKey: "sharednot")
                } catch {
                    // alert no connection
                    preventDoubleTriggerShared = true
                    sharedNoti = true
                    cloudViewModel.notiSharedOn = true
                    UserDefaults.standard.set(true, forKey: "sharednot")
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    showingErrorNoConnection = true
                }
                discoverProcess = false
            }
        }
        if preventDoubleTriggerShared {
            preventDoubleTriggerShared = false
        }
    }
    
    private func triggerDiscoverNoti(_ newValue: Bool) {
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
                        mapViewModel.getPlacmarkOfLocation(location: CLLocation(latitude: mapViewModel.region.center.latitude, longitude: mapViewModel.region.center.longitude), isPrecise: false) { place in
                            placeName = place
                            UserDefaults.standard.set(place, forKey: "discovernotiname")
                        }
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
                    try await cloudViewModel.unsubscribeAllPublic()
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
    
    private func checkForErrors() {
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
    }
    
    private func setNewColor(_ newColor: Color) {
        let color = UIColor(newColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(green), forKey: "colorg")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(blue), forKey: "colorb")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(red), forKey: "colorr")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(alpha), forKey: "colora")
    }
    
    private func setNewColorFromIndex(index: Int) {
        let color = UIColor(cloudViewModel.systemColorArray[index])
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(green), forKey: "colorg")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(blue), forKey: "colorb")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(red), forKey: "colorr")
        UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.set(Double(alpha), forKey: "colora")
    }
    
    private func initializeVars() {
        if cloudViewModel.notiNewSpotOn ==  true {
            preventDoubleTrigger = true
        }
        discoverNoti = cloudViewModel.notiNewSpotOn
        if cloudViewModel.notiSharedOn ==  true {
            preventDoubleTriggerShared = true
        }
        sharedNoti = cloudViewModel.notiSharedOn
    }
}
