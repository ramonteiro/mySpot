//
//  ContentView.swift
//  My Spot
//
//  Created by Isaac Paschall on 3/8/22.
//

import WelcomeSheet
import SwiftUI

struct ContentView: View {

    private let whatsNewPages = [
        WelcomeSheetPage(title: "What's New".localized(), rows: [
            WelcomeSheetPageRow(imageSystemName: "applewatch.radiowaves.left.and.right", title: "Apple Watch Support".localized(), content: "Use the apple watch extension to quickly find spots near you.".localized()),
            WelcomeSheetPageRow(imageSystemName: "square.text.square", title: "Widgets", content: "Add widgets to your home screen to find spots near you at a glance.".localized()),
            WelcomeSheetPageRow(imageSystemName: "person.3", title: "Shared Playlists".localized(), content: "Build your playlists with friends! Tap the person icon in any playlist to add people.".localized()),
            WelcomeSheetPageRow(imageSystemName: "bell", title: "Notifications".localized(), content: "Get notified when new spots are added near you, or when your shared playlists are modified. Go to settings to turn on notifications.".localized())
        ], mainButtonTitle: "Continue".localized())
    ]
    
    private var userid: String {
        if let id = UserDefaults(suiteName: "group.com.isaacpaschall.My-Spot")?.string(forKey: "userid"),
           cloudViewModel.userID.isEmpty {
            return id
        } else if !cloudViewModel.userID.isEmpty {
            return cloudViewModel.userID
        } else {
            return "error"
        }
    }
    
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
    @State private var didDelete = false
    @State private var splashAnimation = false
    @State private var removeSplashScreen = false
    
    var body: some View {
        ZStack {
            content
            if !removeSplashScreen {
                splashScreen
            }
        }
    }
    
    // MARK: - Sub Views
    
    private var content: some View {
        ZStack {
            GeometryReader { geo in
                tabView
                plusButton(geo: geo)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var splashScreen: some View {
        Color("LaunchScreenColor")
            .overlay(
                Image("LaunchScreenImage")
                    .resizable()
                    .frame(width: 256, height: 256)
                    .foregroundColor(Color("Color"))
                    .scaleEffect(splashAnimation ? 35 : 1)
            )
            .ignoresSafeArea()
    }
    
    private var tabView: some View {
        TabView(selection: $tabController.activeTab) {
            mySpotTab
            discoverTab
            addSpotTab
            playlistTab()
            profileTab
        }
        .onChange(of: cloudViewModel.isSignedInToiCloud) { signedIn in
            checkForValidProfile(isSignedInToiCloud: signedIn)
        }
        .onChange(of: cloudViewModel.AccountModelToggle) { _ in
            presentSharedAccount.toggle()
        }
        .onChange(of: cloudViewModel.sharedSpotToggle) { _ in
            presentSharedSpotSheet.toggle()
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
            if let spot = cloudViewModel.shared {
                DetailView(isSheet: true, from: Tab.discover, spot: spot, didDelete: $didDelete)
            }
        }
        .fullScreenCover(isPresented: $presentSharedAccount) {
            if let userid = cloudViewModel.deepAccount {
                AccountDetailView(userid: userid)
            }
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
    
    private func playlistTab() -> some View {
        let viewModel = PlaylistViewModel(mapViewModel: mapViewModel, cloudViewModel: cloudViewModel)
        return PlaylistView(viewModel: viewModel, factory: PlaylistSubviewsFactory(viewModel: viewModel))
            .tabItem() {
                Image(systemName: "books.vertical")
                Text("Playlists".localized())
            }
            .tag(Tab.playlists)
            .badge(UserDefaults.standard.integer(forKey: "badgeplaylists"))
    }
    
    private var profileTab: some View {
        AccountDetailView(userid: userid)
            .tabItem() {
                Image(systemName: "person.fill")
                Text("Profile".localized())
            }
            .tag(Tab.profile)
            .badge(UserDefaults.standard.integer(forKey: "badge"))
    }
    
    private func plusButton(geo: GeometryProxy) -> some View {
        Image(systemName: "plus")
            .resizable()
            .frame(width: 20, height: 20, alignment: .center)
            .padding(10)
            .background(addedSpotIsSaving ? Color.gray : cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            .clipShape(Circle())
            .offset(x: geo.size.width / 2 - 20, y: geo.size.height - 40)
            .foregroundColor(.white)
            .onTapGesture {
                Task { try? await cloudViewModel.isBanned() }
                presentAddSpotSheet.toggle()
            }
            .disabled(addedSpotIsSaving)
    }
    
    // MARK: - Functions
    
    private func checkForValidProfile(isSignedInToiCloud: Bool) {
        if isSignedInToiCloud {
            Task {
                let doesAccountExist = await cloudViewModel.doesAccountExist(for: cloudViewModel.userID)
                if !doesAccountExist {
                    presentAccountCreation.toggle()
                } else {
                    try? await cloudViewModel.getMemberSince(fromid: cloudViewModel.userID)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    splashAnimation.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        removeSplashScreen.toggle()
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
