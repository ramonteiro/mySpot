//
//  NotificationView.swift
//  My Spot
//
//  Created by Isaac Paschall on 5/7/22.
//

import SwiftUI

struct NotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @State private var showDetailView = false
    @State private var canLoad = false
    @State private var index: Int?
    @State private var hasError = false
    @State private var isFetching = false
    @State private var showSettings = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            if !cloudViewModel.notiNewSpotOn && cloudViewModel.notificationSpots.isEmpty {
                noNotification
            } else if cloudViewModel.notificationSpots.isEmpty && !isFetching {
                noSpotsMessage
            } else {
                stack
                    .navigationTitle("Notifications".localized())
                    .navigationViewStyle(.stack)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.warning)
                                showingAlert.toggle()
                            } label: {
                                Text("Remove All".localized())
                                    .foregroundColor(.red)
                            }
                            .disabled(isFetching || cloudViewModel.notificationSpots.isEmpty)
                        }
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            Button {
                                presentationMode.wrappedValue.dismiss()
                            } label: {
                                Text("Done".localized())
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .alert("Are you sure you want to remove all notifications?".localized(), isPresented: $showingAlert) {
            Button("Remove All".localized(), role: .destructive) {
                cloudViewModel.notificationSpots = []
                if UserDefaults.standard.valueExists(forKey: "newSpotNotiRecords") {
                    UserDefaults.standard.set([], forKey: "newSpotNotiRecords")
                }
            }
        }
        .onAppear {
            UIApplication.shared.applicationIconBadgeNumber = 0
            UserDefaults.standard.set(0, forKey: "badge")
            cloudViewModel.resetBadge()
            reloadData()
        }
    }
    
    private var noNotification: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("No Notifications".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            HStack {
                Spacer()
                Button {
                    showSettings.toggle()
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
    }
    
    private var noSpotsMessage: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Text("No Notifications".localized())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
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
    }
    
    private func reloadData() {
        guard let recordids = UserDefaults.standard.stringArray(forKey: "newSpotNotiRecords") else {
            return
        }
        if recordids.isEmpty { return }
        Task {
            isFetching = true
            cloudViewModel.notificationSpots.removeAll()
            do {
                for recordid in recordids {
                    try await cloudViewModel.fetchNotificationSpots(recordid: recordid)
                }
                isFetching = false
            } catch {
                isFetching = false
                hasError = true
            }
        }
    }
    
    private var listSpots: some View {
        VStack {
            List {
                ForEach(cloudViewModel.notificationSpots.indices, id: \.self) { i in
                    Button {
                        index = i
                        showDetailView = true
                    } label: {
                        DiscoverRow(spot: cloudViewModel.notificationSpots[i])
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
            NavigationLink(destination: DiscoverDetailNotification(index: index ?? 0, canShare: true), isActive: $showDetailView) {
                EmptyView()
            }
            .isDetailLink(false)
        }
    }
    
    private var stack: some View {
        ZStack {
            listSpots
            if (isFetching) {
                ZStack {
                    ProgressView("Loading Spots".localized())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
            if hasError {
                VStack {
                    HStack {
                        Spacer()
                        Text("Unable to load spots".localized())
                            .foregroundColor(.gray)
                            .font(.headline)
                        Spacer()
                    }
                    HStack {
                        Spacer()
                        Text("Try refreshing or checking your internet connection".localized())
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 2)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                )
                .onAppear {
                    if cloudViewModel.notificationSpots.count != 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            withAnimation {
                                hasError.toggle()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func removeRows(at offsets: IndexSet) {
        guard var recordid = UserDefaults.standard.stringArray(forKey: "newSpotNotiRecords") else { return }
        recordid.remove(atOffsets: offsets)
        cloudViewModel.notificationSpots.remove(atOffsets: offsets)
    }
}
