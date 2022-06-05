//
//  AccountDetailView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/4/22.
//

import SwiftUI

struct AccountDetailView: View {
    
    @State var isFetching: Bool = false
    @State var userid: String
    @State var image: UIImage
    @State var name: String
    @State var downloads: Int
    @State var spotCount: Int
    @State var pronouns: String?
    @State var bio: String?
    @State var email: String?
    @State var tiktok: String?
    @State var insta: String?
    @State var youtube: String?
    @State var editAlert: Bool = false
    @State var spots: [SpotFromCloud] = []
    @State private var isShare = false
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(spots.indices, id: \.self) { i in
                            NavigationLink {
                                DiscoverDetailAccountSpots(index: i, spotsFromCloud: $spots, canShare: false)
                            } label: {
                                DiscoverRow(spot: spots[i])
                                    .padding(3)
                            }
                        }
                    }
                }
            }
            .background(ShareViewController(isPresenting: $isShare) {
                let av = shareSheetAccount(userid: cloudViewModel.userID, name: name)
                av.completionWithItemsHandler = { _, _, _, _ in
                    isShare = false
                }
                return av
            })
            .navigationTitle("Account".localized())
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            isShare = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button {
                            editAlert.toggle()
                        } label: {
                            Text("Edit".localized())
                        }
                    }
                }
            }
            .onAppear {
                if spots.isEmpty {
                    Task {
                        await fetchSpots()
                    }
                }
            }
            .fullScreenCover(isPresented: $editAlert) {
                EmptyView()
            }
        }
    }
    
    private func shareSheetAccount(userid: String, name: String) -> UIActivityViewController {
        return UIActivityViewController(activityItems: ["Check out, \"".localized() + name + "\" on My Spot! ".localized(), URL(string: "myspot://" + (userid)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ".localized(), URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
    }
    
    private func fetchSpots() async {
        if isFetching { return }
        isFetching = true
        do {
            spots = try await cloudViewModel.fetchAccountSpots(userid: userid)
        } catch {
            print("failed to fetch")
        }
        isFetching = false
    }
}
