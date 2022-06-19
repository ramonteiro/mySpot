//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import WelcomeSheet
import SwiftUI

struct ContentView: View {

    let whatsNewPages = [
        WelcomeSheetPage(title: "What's New".localized(), rows: [
            WelcomeSheetPageRow(imageSystemName: "applewatch.radiowaves.left.and.right", title: "Apple Watch Support".localized(), content: "Use the apple watch extension to quickly find spots near you.".localized()),
            WelcomeSheetPageRow(imageSystemName: "square.text.square", title: "Widgets", content: "Add widgets to your home screen to find spots near you at a glance.".localized()),
            WelcomeSheetPageRow(imageSystemName: "person.3", title: "Shared Playlists".localized(), content: "Build your playlists with friends! Tap the person icon in any playlist to add people.".localized()),
            WelcomeSheetPageRow(imageSystemName: "bell", title: "Notifications".localized(), content: "Get notified when new spots are added near you, or when your shared playlists are modified. Go to settings to turn on notifications.".localized())
        ], mainButtonTitle: "Continue".localized())
    ]
    
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var mapViewModel: MapViewModel
    @EnvironmentObject var phoneViewModel: PhoneViewModel
    @EnvironmentObject var tabController: TabController
    @State private var presentSharedSpotSheet = false
    @State private var presentAccountCreation = false
    @State private var presentErrorAlert = false
    @State private var presentSharedAccount = false
    @State private var presentAddSpotSheet = false
    @State private var presentAddSpotErrorAlert = false
    @State private var presentFailedToAcceptShareInviteAlert = false
    @State private var presentShareInviteAcceptedSuccessfullyAlert = false
    @State private var prsentWhatsNewWelcomeSheet = false
    @State private var errorAddingSpot = false
    @State private var addedSpotIsSaving = false
    @State private var doNotTriggerRepeatWhenTabSelectionChanges = false
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                tabView
                addSpotButton(geo: geo)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Sub Views
    
    private var tabView: some View {
        TabView(selection: $tabController.activeTab) {
            mySpotTab
            discoverTab
            addSpotTab
            playlistTab
            profileTab
        }
        .onChange(of: cloudViewModel.isSignedInToiCloud) { signedIn in
            checkForValidProfile(isSignedInToiCloud: signedIn)
        }
        .onChange(of: cloudViewModel.sharedAccount.count) { accounts in
            presentSharedAccount(accounts: accounts)
        }
        .onChange(of: cloudViewModel.shared.count) { spots in
            presentSharedSpot(spots: spots)
        }
        .onChange(of: cloudViewModel.isError) { _ in
            presentCloudError()
        }
        .onChange(of: CoreDataStack.shared.recievedShare) { _ in
            presentShareInviteAlert()
        }
        .onReceive(tabController.$activeTab) { selection in
            controlTapsOfTabBarItems(newSelection: selection)
        }
        .alert("Unable To Upload Spot".localized(), isPresented: $presentAddSpotErrorAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Please check internet connection and try again.".localized())
        }
        .alert("Invite Accepted!".localized(), isPresented: $presentShareInviteAcceptedSuccessfullyAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("It may take a few seconds for the playlist to appear.".localized())
        }
        .alert("Invalid Invite".localized(), isPresented: $presentFailedToAcceptShareInviteAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text("Please ask for another invite or check internet connection.".localized())
        }
        .alert(cloudViewModel.isErrorMessage, isPresented: $presentErrorAlert) {
            Button("OK".localized(), role: .cancel) { }
        } message: {
            Text(cloudViewModel.isErrorMessageDetails)
        }
        .fullScreenCover(isPresented: $presentSharedSpotSheet) {
            cloudViewModel.shared = []
        } content: {
            DiscoverSheetShared()
        }
        .fullScreenCover(isPresented: $presentSharedAccount) {
            AccountDetailView(userid: cloudViewModel.sharedAccount)
        }
        .fullScreenCover(isPresented: $presentAccountCreation) {
            dismissAccountCreation()
        } content: {
            CreateAccountView(accountModel: nil)
        }
        .sheet(isPresented: $presentAddSpotSheet) {
            dismissAddSpotSheet()
        } content: {
            AddSpotSheet(isSaving: $addedSpotIsSaving, showingCannotSavePublicAlert: $errorAddingSpot)
        }
        .welcomeSheet(isPresented: $prsentWhatsNewWelcomeSheet,
                      onDismiss: { UserDefaults.standard.set(true, forKey: "whatsnew") },
                      isSlideToDismissDisabled: false,
                      pages: whatsNewPages)
    }
    
    @ViewBuilder
    private func addSpotButton(geo: GeometryProxy) -> some View {
        if !addedSpotIsSaving {
            plusButton(geo: geo)
        } else {
            savingSpotSpinner(geo: geo)
        }
    }
    
    private var mySpotTab: some View {
        MySpotsView()
            .tabItem() {
                Image(systemName: "mappin.and.ellipse")
                Text("My Spots")
            }
            .tag(Tab.spots)
    }
    
    private var discoverTab: some View {
        DiscoverView()
            .tabItem() {
                Image(systemName: "magnifyingglass")
                Text("Discover".localized())
            }
            .tag(Tab.discover)
    }
    
    private var addSpotTab: some View {
        Text("")
            .tabItem {
                Text("")
            }
            .tag(Tab.addSpot)
    }
    
    private var playlistTab: some View {
        PlaylistView()
            .tabItem() {
                Image(systemName: "books.vertical")
                Text("Playlists".localized())
            }
            .tag(Tab.playlists)
            .badge(UserDefaults.standard.integer(forKey: "badgeplaylists"))
    }
    
    private var profileTab: some View {
        AccountDetailView(userid: (cloudViewModel.userID.isEmpty ? UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid") ?? cloudViewModel.userID : cloudViewModel.userID))
            .tabItem() {
                Image(systemName: "person.fill")
                Text("Profile".localized())
            }
            .tag(Tab.profile)
            .badge(UserDefaults.standard.integer(forKey: "badge"))
    }
    
    private func plusButton(geo: GeometryProxy) -> some View {
        Image(systemName: "plus.app")
            .resizable()
            .frame(width: 40, height: 40, alignment: .center)
            .offset(x: geo.size.width / 2 - 20, y: geo.size.height - 40)
            .foregroundColor(.gray)
            .onTapGesture {
                UserDefaults.standard.set(Double(-1.0), forKey: "tempPinX")
                Task { try? await cloudViewModel.isBanned() }
                presentAddSpotSheet.toggle()
            }
            .disabled(addedSpotIsSaving)
    }
    
    private func savingSpotSpinner(geo: GeometryProxy) -> some View {
        ProgressView()
            .progressViewStyle(.circular)
            .frame(width: geo.size.width / 7, height: geo.size.width / 7, alignment: .center)
            .offset(x: geo.size.width / 2 - ((geo.size.width / 7) / 2), y: geo.size.height - (geo.size.height * 0.025) - ((geo.size.width / 7) / 2))
    }
    
    // MARK: - Functions
    
    private func checkForValidProfile(isSignedInToiCloud: Bool) {
        if isSignedInToiCloud {
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
    
    private func controlTapsOfTabBarItems(newSelection: Tab) {
        if doNotTriggerRepeatWhenTabSelectionChanges {
            doNotTriggerRepeatWhenTabSelectionChanges = false
            return
        }
        if (newSelection == Tab.spots) {
            if (newSelection == tabController.lastPressedTab) {
                tabController.spotPopToRoot.toggle()
            }
        }
        if (newSelection == Tab.playlists) {
            if (newSelection == tabController.lastPressedTab) {
                tabController.playlistPopToRoot.toggle()
            }
        }
        if (newSelection == Tab.discover) {
            if (newSelection == tabController.lastPressedTab) {
                tabController.discoverPopToRoot.toggle()
            }
        }
        if (newSelection == Tab.profile) {
            if (newSelection == tabController.lastPressedTab) {
                tabController.profilePopToRoot.toggle()
            }
        }
        if (newSelection == Tab.addSpot) {
            tabController.open(tabController.lastPressedTab)
            doNotTriggerRepeatWhenTabSelectionChanges = true
            return
        }
        tabController.lastPressedTab = newSelection
    }
    
    private func presentSharedAccount(accounts: Int) {
        if accounts == 1 {
            presentSharedAccount.toggle()
        }
    }
    
    private func presentSharedSpot(spots: Int) {
        if spots == 1 {
            presentSharedSpotSheet.toggle()
        }
    }
    
    private func presentCloudError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        presentErrorAlert.toggle()
    }
    
    private func dismissAddSpotSheet() {
        if errorAddingSpot {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            presentAddSpotErrorAlert.toggle()
            errorAddingSpot = false
        }
    }
    
    private func presentShareInviteAlert() {
        if CoreDataStack.shared.wasSuccessful {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            presentShareInviteAcceptedSuccessfullyAlert = true
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentFailedToAcceptShareInviteAlert = true
        }
    }
    
    private func dismissAccountCreation() {
        if CoreDataStack.shared.wasSuccessful {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            presentShareInviteAcceptedSuccessfullyAlert = true
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            presentFailedToAcceptShareInviteAlert = true
        }
    }
}
