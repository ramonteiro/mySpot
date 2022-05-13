//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var phoneViewModel: PhoneViewModel
    @StateObject private var tabController = TabController()
    @FetchRequest(sortDescriptors: []) var colors: FetchedResults<CustomColor>
    @Environment(\.managedObjectContext) var moc
    @State private var showSharedSpotSheet = false
    @State private var errorAlert = false
    //accepting share alerts
    @State private var failedToAcceptShare = false
    @State private var acceptedShare = false
    
    var body: some View {
        TabView(selection: $tabController.activeTab) {
            MySpotsView()
                .tabItem() {
                    Image(systemName: "mappin.and.ellipse")
                    Text("My Spots")
                }
                .tag(Tab.spots)
            DiscoverView()
                .tabItem() {
                    Image(systemName: "magnifyingglass")
                    Text("Discover".localized())
                }
                .tag(Tab.discover)
            PlaylistView()
                .tabItem() {
                    Image(systemName: "books.vertical")
                    Text("Playlists".localized())
                }
                .tag(Tab.playlists)
            SettingsView()
                .tabItem() {
                    Image(systemName: "gear")
                    Text("Settings".localized())
                }
                .tag(Tab.settings)
                .badge(UIApplication.shared.applicationIconBadgeNumber)
        }
        .onChange(of: scenePhase, perform: { newValue in
            if newValue == .active {
                cloudViewModel.getiCloudStatus()
                mapViewModel.checkLocationAuthorization()
            }
        })
        .onReceive(tabController.$activeTab) { selection in
            if (selection == Tab.spots) {
                // spot pressed
                
                if (selection == tabController.lastPressedTab) {
                    // spot pressed while in spot
                    tabController.spotPopToRoot.toggle()
                }
            }
            if (selection == Tab.playlists) {
                // playlist pressed
                
                if (selection == tabController.lastPressedTab) {
                    // playlist pressed while in playlist
                    tabController.playlistPopToRoot.toggle()
                }
            }
            if (selection == Tab.discover) {
                // discover pressed
                
                if (selection == tabController.lastPressedTab) {
                    // discover pressed while in discover
                    tabController.discoverPopToRoot.toggle()
                }
            }
            
            // set last changed tab
            tabController.lastPressedTab = selection
        }
        .fullScreenCover(isPresented: $showSharedSpotSheet, onDismiss: {
            cloudViewModel.shared = []
        }, content: {
            DiscoverSheetShared()
        })
        .onChange(of: cloudViewModel.shared.count) { newValue in
            if newValue == 1 {
                showSharedSpotSheet = true
            }
        }
        .onChange(of: cloudViewModel.isError) { _ in
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            errorAlert.toggle()
        }
        .alert(cloudViewModel.isErrorMessage, isPresented: $errorAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(cloudViewModel.isErrorMessageDetails)
        }
        .environmentObject(tabController)
        .onChange(of: CoreDataStack.shared.recievedShare) { _ in
            if CoreDataStack.shared.wasSuccessful {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                acceptedShare = true
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                failedToAcceptShare = true
            }
        }
        .alert("Invite Accepted!".localized(), isPresented: $acceptedShare) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("It may take a few seconds for the playlist to appear.".localized())
        }
        .alert("Invalid Invite".localized(), isPresented: $failedToAcceptShare) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Please ask for another invite or check internet connection.".localized())
        }
        .onAppear {
            if colors.isEmpty {
                let newColor = CustomColor(context: moc)
                newColor.colorIndex = 0
                newColor.colorR = 128
                newColor.colorA = 128
                newColor.name = ""
                newColor.colorB = 128
                newColor.colorG = 128
                do {
                    try moc.save()
                    cloudViewModel.systemColorArray[cloudViewModel.systemColorArray.count - 1] = Color(uiColor: UIColor(red: colors[0].colorR, green: colors[0].colorG, blue: colors[0].colorB, alpha: colors[0].colorA))
                    cloudViewModel.systemColorIndex = Int(colors[0].colorIndex)
                    cloudViewModel.savedName = colors[0].name ?? ""
                } catch {
                    print("error reading moc")
                }
            } else {
                cloudViewModel.systemColorArray[cloudViewModel.systemColorArray.count - 1] = Color(uiColor: UIColor(red: colors[0].colorR, green: colors[0].colorG, blue: colors[0].colorB, alpha: colors[0].colorA))
                cloudViewModel.systemColorIndex = Int(colors[0].colorIndex)
            }
        }
    }
}
