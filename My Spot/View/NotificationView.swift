//
//  NotificationView.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/7/22.
//

import SwiftUI

struct NotificationView: View {
    
    @Binding var badgeNum: Int
    @Binding var goToSettings: Bool
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var presentDetailView = false
    @State private var presentRemoveAllAlert = false
    @State private var index: Int?
    @State private var hasError = false
    @State private var isFetching = false
    @State private var spots: [SpotFromCloud] = []
    @State private var didDelete = false
    
    var body: some View {
        NavigationView {
            notificationMainView
        }
        .alert("Are you sure you want to remove all notifications?".localized(), isPresented: $presentRemoveAllAlert) {
            Button("Remove All".localized(), role: .destructive) {
                removeNotificationSpots()
            }
        }
        .onAppear {
            removeBadges()
            reloadData()
        }
    }
    
    // MARK: - Sub Views
    
    @ViewBuilder
    private var notificationMainView: some View {
        if !cloudViewModel.notiNewSpotOn && spots.isEmpty {
            noNotification
        } else if spots.isEmpty && !isFetching {
            noSpotsMessage
        } else {
            notificationSpots
        }
    }
    
    private var notificationSpots: some View {
        ZStack {
            listSpots
            if isFetching {
                loadingSpotsSpinner
            }
            if hasError {
                errorLoadingSpots
            }
        }
        .navigationTitle("Notifications".localized())
        .navigationViewStyle(.stack)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                removeAllButton
            }
            ToolbarItemGroup(placement: .navigationBarLeading) {
                doneButton
            }
        }
    }
    
    private var removeAllButton: some View {
        Button {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            presentRemoveAllAlert.toggle()
        } label: {
            Text("Remove All".localized())
                .foregroundColor(.red)
        }
        .disabled(isFetching || spots.isEmpty)
    }
    
    private var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done".localized())
        }
    }
    
    private var loadingSpotsSpinner: some View {
        ProgressView("Loading Spots".localized())
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
            )
    }
    
    private var errorLoadingSpots: some View {
        VStack {
            errorLoadingSpotsTitle
            errorLoadingSpotsSubtitle
        }
        .padding(.vertical)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
        .onAppear {
            checkIfNotificationSpotsHaveLoaded()
        }
    }
    
    private var errorLoadingSpotsTitle: some View {
        HStack {
            Spacer()
            Text("Unable to load spots".localized())
                .foregroundColor(.gray)
                .font(.headline)
            Spacer()
        }
    }
    
    private var errorLoadingSpotsSubtitle: some View {
        HStack {
            Spacer()
            Text("Try refreshing or checking your internet connection".localized())
                .foregroundColor(.gray)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
    
    private var noNotification: some View {
        VStack(spacing: 6) {
            noNotificationTitle
            noNotificationSubtitle
        }
    }
    
    private var noNotificationTitle: some View {
        HStack {
            Spacer()
            Text("No Notifications".localized())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    private var noNotificationSubtitle: some View {
        HStack {
            Spacer()
            Button {
                goToSettings = true
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Please go to settings to enable notifications".localized())
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
    
    private var noSpotsMessage: some View {
        VStack(spacing: 6) {
            noSpotsMessageTitle
            noSpotsMessageSubtitle
        }
    }
    
    private var noSpotsMessageTitle: some View {
        HStack {
            Spacer()
            Text("No Notifications".localized())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    private var noSpotsMessageSubtitle: some View {
        HStack {
            Spacer()
            Text("Your notifications will arrive here".localized())
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    private var listSpots: some View {
        VStack {
            List {
                ForEach(spots.indices, id: \.self) { i in
                    Button {
                        index = i
                        presentDetailView = true
                    } label: {
                        SpotRow(spot: $spots[i])
                    }
                }
                .onDelete(perform: removeRows)
            }
            .animation(.default, value: cloudViewModel.notificationSpots)
            .if(cloudViewModel.canRefresh) { view in
                view.refreshable {
                    reloadData()
                }
            }
            .onAppear {
                cloudViewModel.canRefresh = true
            }
            NavigationLink(destination: DetailView(isSheet: false, from: Tab.discover, spot: spots[index ?? 0], didDelete: $didDelete), isActive: $presentDetailView) {
                EmptyView()
            }
            .isDetailLink(false)
        }
    }
    
    // MARK: - Functions
    
    private func removeBadges() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        UserDefaults.standard.set(0, forKey: "badge")
        badgeNum = 0
        cloudViewModel.resetBadgeNewSpots()
    }
    
    private func removeNotificationSpots() {
        spots = []
        if UserDefaults.standard.valueExists(forKey: "newSpotNotiRecords") {
            UserDefaults.standard.set([], forKey: "newSpotNotiRecords")
        }
    }
    
    private func removeRows(at offsets: IndexSet) {
        guard var recordid = UserDefaults.standard.stringArray(forKey: "newSpotNotiRecords") else { return }
        recordid.remove(atOffsets: offsets)
        spots.remove(atOffsets: offsets)
    }
    
    private func reloadData() {
        guard let recordids = UserDefaults.standard.stringArray(forKey: "newSpotNotiRecords") else {
            return
        }
        if recordids.isEmpty { return }
        Task {
            isFetching = true
            do {
                for recordid in recordids {
                    let spot = try await cloudViewModel.fetchNotificationSpots(recordid: recordid)
                    if let spot = spot {
                        spots.append(spot)
                    }
                }
                isFetching = false
            } catch {
                isFetching = false
                hasError = true
            }
        }
    }
    
    private func checkIfNotificationSpotsHaveLoaded() {
        if spots.count != 0 {
            withAnimation {
                hasError = false
            }
        }
    }
}
