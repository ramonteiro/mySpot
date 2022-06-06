//
//  AccountDetailView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/4/22.
//

import SwiftUI

struct AccountDetailView: View {
    
    @State private var isFetching: Bool = false
    @State var userid: String
    @State var myAccount: Bool
    @State private var accountModel: AccountModel?
    @State private var image: UIImage = defaultImages.errorImage!
    @State private var name: String = "Account".localized()
    @State private var downloads: Int = 0
    @State private var spotCount: Int = 0
    @State private var isExplorer: Bool = false
    @State private var memberSince: Date?
    @State private var pronouns: String?
    @State private var bio: String?
    @State private var email: String?
    @State private var tiktok: String?
    @State private var insta: String?
    @State private var youtube: String?
    @State private var editAlert: Bool = false
    @State private var spots: [SpotFromCloud] = []
    @State private var linkDictionary: [String: URL] = [:]
    @State private var spotBadgeColor: Color = .gray
    @State private var downloadBadgeColor: Color = .gray
    @State private var badges: [String] = []
    @State private var isShare = false
    @State private var infoAlert = false
    @State private var tappedBadge = "flag"
    @State private var openSettings = false
    @State private var showNotificationSheet = false
    @State private var badgeNum = 0
    @State private var goToSettings = false
    @State private var isLoading = true
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var tabController: TabController
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                if !isLoading {
                    VStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .padding(.bottom, 5)
                        stats
                            .padding(.bottom, 30)
                        links
                        if let bio = bio {
                            Text(bio)
                                .frame(maxWidth: UIScreen.screenWidth * 0.6)
                                .multilineTextAlignment(.center)
                                .font(.callout)
                                .padding(.top, 5)
                        }
                        HStack {
                            Text("Spots:")
                                .font(.headline)
                            Spacer()
                            badgeView
                        }
                        .padding(.top, 5)
                        .padding(.leading, 3)
                        ZStack {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(spots.indices, id: \.self) { i in
                                    NavigationLink {
                                        DiscoverDetailAccountSpots(index: i, spotsFromCloud: $spots, canShare: true, myAccount: myAccount)
                                    } label: {
                                        DiscoverRow(spot: spots[i])
                                            .padding(4)
                                    }
                                }
                                .padding(.horizontal, 15)
                                if cloudViewModel.cursorAccount != nil && !isFetching {
                                    loadMoreSpots
                                }
                            }
                            if isFetching {
                                ProgressView("Loading Spots".localized())
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.systemBackground))
                                    )
                            }
                        }
                    }
                } else {
                    ProgressView("Loading Account".localized())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.systemBackground))
                        )
                }
            }
            .alert(badgeName().localized() + " " + "Badge".localized(), isPresented: $infoAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text(badgeMessage().localized())
            }
            .background(ShareViewController(isPresenting: $isShare) {
                let av = shareSheetAccount(userid: cloudViewModel.userID, name: name)
                av.completionWithItemsHandler = { _, _, _, _ in
                    isShare = false
                }
                return av
            })
            .fullScreenCover(isPresented: $openSettings) {
                SettingsView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .sheet(isPresented: $showNotificationSheet, onDismiss: {
                if goToSettings == true {
                    goToSettings = false
                    openSettings = true
                }
            }) {
                NotificationView(badgeNum: $badgeNum, goToSettings: $goToSettings)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        if UIDevice.current.userInterfaceIdiom != .pad {
                            Button {
                                isShare = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        if myAccount && accountModel != nil {
                            Button {
                                editAlert.toggle()
                            } label: {
                                Text("Edit".localized())
                            }
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if myAccount {
                        Button {
                            openSettings.toggle()
                        } label: {
                            Image(systemName: "gear")
                        }
                        Button {
                            showNotificationSheet.toggle()
                        } label: {
                            Image(systemName: "bell")
                        }
                        .if(badgeNum > 0) { view in
                            view.overlay {
                                Badge(count: $badgeNum, color: .red)
                            }
                        }
                    } else {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Done".localized())
                        }
                    }
                }
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text(name)
                            .font(.headline)
                        if let pronouns = pronouns {
                            Text(pronouns)
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        let fetchedArr = try await cloudViewModel.getDownloadsAndSpots(from: userid)
                        downloads = fetchedArr[0]
                        spotCount = fetchedArr[1]
                    } catch {
                        print("failed to load spot count")
                    }
                    do {
                        accountModel = try await cloudViewModel.fetchAccount(userid: userid)
                        if let account = accountModel {
                            name = account.name
                            image = account.image
                            pronouns = account.pronouns
                            tiktok = account.tiktok
                            youtube = account.youtube
                            insta = account.insta
                            bio = account.bio
                            if bio == "Unable to load account".localized() {
                                bio = ""
                            }
                            isExplorer = account.isExplorer
                            if let date = account.record.creationDate {
                                memberSince = date
                            }
                        }
                    } catch {
                        bio = "Unable to load account".localized()
                        print("failed to fetch account")
                        print(error)
                    }
                    initializeBadgesAndLinks()
                    withAnimation {
                        isLoading = false
                    }
                    if spots.isEmpty {
                        await fetchSpots()
                    }
                }
            }
            .fullScreenCover(isPresented: $editAlert, onDismiss: {
                Task {
                    await refreshAccount()
                }
            }) {
                if let accountModel = accountModel {
                    CreateAccountView(accountModel: accountModel)
                }
            }
        }
    }
    
    private func badgeMessage() -> String {
        if tappedBadge == "flag" {
            return "Given to users who create a spot with their current location (not custom) and no other spots exist within a 10 mile radius."
        } else if tappedBadge == "heart" {
            return "Given to users who have been a member since 2022."
        } else if tappedBadge == "mappin.and.ellipse" {
            if spotCount > 100 {
                return "Given to users who have over 100 spots."
            } else if spotCount > 50 {
                return "Given to users who have over 50 spots."
            } else if spotCount > 10 {
                return "Given to users who have over 10 spots."
            }
        } else if tappedBadge == "icloud.and.arrow.down" {
            if downloads > 250 {
                return "Given to users who have over 250 downloads."
            } else if downloads > 100 {
                return "Given to users who have over 100 downloads."
            } else if downloads > 50 {
                return "Given to users who have over 50 downloads."
            }
        }
        return ""
    }
    
    private func badgeName() -> String {
        if tappedBadge == "flag" {
            return "Flag"
        } else if tappedBadge == "heart" {
            return "OG"
        } else if tappedBadge == "mappin.and.ellipse" {
           if spotCount > 100 {
               return "Diamond Spotter"
           } else if spotCount > 50 {
               return "Gold Spotter"
           } else if spotCount > 10 {
               return "Spotter"
           }
       } else if tappedBadge == "icloud.and.arrow.down" {
           if downloads > 250 {
               return "Diamond Downloads"
           } else if downloads > 100 {
               return "Gold Downloads"
           } else if downloads > 50 {
               return "Downloads"
           }
       }
        return ""
    }
    
    private var loadMoreSpots: some View {
        HStack {
            Spacer()
            Text("Load More Spots".localized())
                .foregroundColor(cloudViewModel.systemColorArray[cloudViewModel.systemColorIndex])
            Spacer()
        }
        .onTapGesture {
            if isFetching { return }
            if let cursor = cloudViewModel.cursorAccount {
                Task {
                    isFetching = true
                    do {
                        spots += try await cloudViewModel.fetchMoreAccountSpots(cursor: cursor)
                    } catch {
                        print("Failed to fetch more spots")
                    }
                    isFetching = false
                }
            }
        }
    }
    
    private func initializeBadgesAndLinks() {
        if UserDefaults.standard.valueExists(forKey: "badge") {
            badgeNum = UserDefaults.standard.integer(forKey: "badge")
        } else {
            UserDefaults.standard.set(0, forKey: "badge")
        }
        if let insta = insta {
            if !insta.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                linkDictionary["insta"] = URL(string: "https://www.instagram.com/" + insta.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if let youtube = youtube {
            if !youtube.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                linkDictionary["youtube"] = URL(string: "https://www.youtube.com/" + youtube.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if let tiktok = tiktok {
            if !tiktok.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                linkDictionary["tiktok"] = URL(string: "https://www.tiktok.com/@" + tiktok.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        if badges.count > 0 { return }
        if isExplorer {
            badges.append("flag")
        }
        if spotCount > 100 {
            badges.append("mappin.and.ellipse")
            spotBadgeColor = Color(uiColor: UIColor(red: 185, green: 245, blue: 255, alpha: 1))
        } else if spotCount > 50 {
            badges.append("mappin.and.ellipse")
            spotBadgeColor = Color(uiColor: UIColor(red: 255, green: 215, blue: 0, alpha: 1))
        } else if spotCount > 10 {
            badges.append("mappin.and.ellipse")
            spotBadgeColor = .white
        }
        if downloads > 250 {
            badges.append("icloud.and.arrow.down")
            downloadBadgeColor = Color(uiColor: UIColor(red: 185, green: 245, blue: 255, alpha: 1))
        } else if downloads > 100 {
            badges.append("icloud.and.arrow.down")
            downloadBadgeColor = Color(uiColor: UIColor(red: 255, green: 215, blue: 0, alpha: 1))
        } else if downloads > 50 {
            badges.append("icloud.and.arrow.down")
            downloadBadgeColor = .white
        }
        if let memberSince = memberSince {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd"
            let year = formatter.date(from: "2023/01/01")
            if let year = year {
                if memberSince < year {
                    badges.append("heart")
                }
            }
        }
    }
    
    private func refreshAccount() async {
        do {
            accountModel = try await cloudViewModel.fetchAccount(userid: userid)
            if let account = accountModel {
                name = account.name
                image = account.image
                pronouns = account.pronouns
                tiktok = account.tiktok
                youtube = account.youtube
                insta = account.insta
                bio = account.bio
                if bio == "Unable to load account".localized() {
                    bio = ""
                }
                isExplorer = account.isExplorer
                if let date = account.record.creationDate {
                    memberSince = date
                }
            }
        } catch {
            bio = "Unable to load account".localized()
            print("failed to fetch account")
            print(error)
        }
    }
    
    private var badgeView: some View {
        HStack {
            ForEach(badges, id: \.self) { badge in
                Image(systemName: badge)
                    .padding(6)
                    .foregroundColor(badge == "mappin.and.ellipse" ? spotBadgeColor : (badge == "icloud.and.arrow.down" ? downloadBadgeColor : .white))
                    .background(Color.gray)
                    .clipShape(Circle())
                    .onTapGesture {
                        tappedBadge = badge
                        infoAlert = true
                    }
                
            }
        }
    }
    
    private var stats: some View {
        GeometryReader { geo in
            HStack(alignment: .center) {
                Spacer()
                VStack {
                    Text("\(downloads)")
                    Text("Downloads".localized())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Rectangle()
                    .fill(colorScheme == .dark ? Color.gray : Color.black)
                    .frame(width: 1, height: geo.size.height * 1.5, alignment: .center)
                VStack {
                    Text("\(spotCount)")
                    Text("Spots")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
    
    private var links: some View {
        HStack {
            ForEach(linkDictionary.sorted(by: {_,_ in return true}), id: \.key) { name, url in
                Button {
                    if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(uiImage: UIImage(named: name + ".png")!)
                        .resizable()
                        .frame(width: 25, height: 25)
                        .padding(10)
                        .background(colorScheme == .dark ? Color.gray : Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
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