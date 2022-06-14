//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import WelcomeSheet
import SwiftUI

struct ContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var phoneViewModel: PhoneViewModel
    @EnvironmentObject var tabController: TabController
    @FetchRequest(sortDescriptors: []) var colors: FetchedResults<CustomColor>
    @Environment(\.managedObjectContext) var moc
    @State private var showSharedSpotSheet = false
    @State private var presentAccountCreation = false
    @State private var errorAlert = false
    @State private var showSharedAccount = false
    // addspot stuff
    @State private var addSpotSheet = false
    @State private var addSpotIsSaving = false
    @State private var addSpotError = false
    @State private var addSpotErrorAlert = false
    @State private var doNotTriggerRepeat = false
    //accepting share alerts
    @State private var failedToAcceptShare = false
    @State private var acceptedShare = false
    //onboarding
    @State private var whatsNew = false
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
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
                    Text("")
                        .tabItem {
                            Text("")
                        }
                        .tag(Tab.addSpot)
                    PlaylistView()
                        .tabItem() {
                            Image(systemName: "books.vertical")
                            Text("Playlists".localized())
                        }
                        .tag(Tab.playlists)
                        .badge(UserDefaults.standard.integer(forKey: "badgeplaylists"))
                    AccountDetailView(userid: (cloudViewModel.userID.isEmpty ? UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") ?? cloudViewModel.userID : cloudViewModel.userID), myAccount: true)
                        .tabItem() {
                            Image(systemName: "person.fill")
                            Text("Profile".localized())
                        }
                        .tag(Tab.profile)
                        .badge(UserDefaults.standard.integer(forKey: "badge"))
                }
                .onChange(of: cloudViewModel.isSignedInToiCloud) { newValue in
                    if newValue {
                        Task {
                            let doesAccountExist = await cloudViewModel.doesAccountExist(for: cloudViewModel.userID)
                            if !doesAccountExist {
                                presentAccountCreation.toggle()
                            } else {
                                Task {
                                    try? await cloudViewModel.getMemberSince(fromid: cloudViewModel.userID)
                                }
                            }
                        }
                    }
                }
                .onChange(of: scenePhase, perform: { newValue in
                    if newValue == .active {
                        cloudViewModel.getiCloudStatus()
                        mapViewModel.checkLocationAuthorization()
                    }
                })
                .onReceive(tabController.$activeTab) { selection in
                    if doNotTriggerRepeat {
                        doNotTriggerRepeat = false
                        return
                    }
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
                    if (selection == Tab.profile) {
                        // discover pressed
                        
                        if (selection == tabController.lastPressedTab) {
                            // discover pressed while in discover
                            tabController.profilePopToRoot.toggle()
                        }
                    }
                    if (selection == Tab.addSpot) {
                        tabController.open(tabController.lastPressedTab)
                        doNotTriggerRepeat = true
                        return
                    }
                    
                    // set last changed tab
                    tabController.lastPressedTab = selection
                }
                .alert("Unable To Upload Spot".localized(), isPresented: $addSpotErrorAlert) {
                    Button("OK".localized(), role: .cancel) { }
                } message: {
                    Text("Please check internet connection and try again.".localized())
                }
                .sheet(isPresented: $addSpotSheet) {
                    if addSpotError {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                        addSpotErrorAlert.toggle()
                        addSpotError = false
                    }
                } content: {
                    AddSpotSheet(isSaving: $addSpotIsSaving, showingCannotSavePublicAlert: $addSpotError)
                }
                .fullScreenCover(isPresented: $showSharedSpotSheet, onDismiss: {
                    cloudViewModel.shared = []
                }, content: {
                    DiscoverSheetShared()
                })
                .fullScreenCover(isPresented: $showSharedAccount) {
                    AccountDetailView(userid: cloudViewModel.sharedAccount, myAccount: false)
                }
                .onChange(of: cloudViewModel.sharedAccount) { newValue in
                    if !newValue.isEmpty {
                        showSharedAccount.toggle()
                    }
                }
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
                .onChange(of: CoreDataStack.shared.recievedShare) { _ in
                    if CoreDataStack.shared.wasSuccessful {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        acceptedShare = true
                    } else {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        failedToAcceptShare = true
                    }
                }
                .fullScreenCover(isPresented: $presentAccountCreation, onDismiss: {
                    if !UserDefaults.standard.bool(forKey: "whatsnew") {
                        whatsNew.toggle()
                    }
                }) {
                    CreateAccountView(accountModel: nil)
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
                .welcomeSheet(isPresented: $whatsNew, onDismiss: {
                    UserDefaults.standard.set(true, forKey: "whatsnew")
                }, isSlideToDismissDisabled: false, pages: whatsNewPages)
                
                if !addSpotIsSaving {
                    Image(systemName: "plus.app")
                        .resizable()
                        .frame(width: 40, height: 40, alignment: .center)
                        .offset(x: geo.size.width / 2 - 20, y: geo.size.height - 40)
                        .foregroundColor(.gray)
                        .onTapGesture {
                            UserDefaults.standard.set(Double(-1.0), forKey: "tempPinX")
                            Task { try? await cloudViewModel.isBanned() }
                            addSpotSheet.toggle()
                        }
                        .disabled(addSpotIsSaving)
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: geo.size.width / 7, height: geo.size.width / 7, alignment: .center)
                        .offset(x: geo.size.width / 2 - ((geo.size.width / 7) / 2), y: geo.size.height - (geo.size.height * 0.025) - ((geo.size.width / 7) / 2))
                }
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // Onboard Screens:
    
    let whatsNewPages = [
        WelcomeSheetPage(title: "What's New".localized(), rows: [
            WelcomeSheetPageRow(imageSystemName: "applewatch.radiowaves.left.and.right", title: "Apple Watch Support".localized(), content: "Use the apple watch extension to quickly find spots near you.".localized()),
            WelcomeSheetPageRow(imageSystemName: "square.text.square", title: "Widgets", content: "Add widgets to your home screen to find spots near you at a glance.".localized()),
            WelcomeSheetPageRow(imageSystemName: "person.3", title: "Shared Playlists".localized(), content: "Build your playlists with friends! Tap the person icon in any playlist to add people.".localized()),
            WelcomeSheetPageRow(imageSystemName: "bell", title: "Notifications".localized(), content: "Get notified when new spots are added near you, or when your shared playlists are modified. Go to settings to turn on notifications.".localized())
        ], mainButtonTitle: "Continue".localized())
    ]
}
