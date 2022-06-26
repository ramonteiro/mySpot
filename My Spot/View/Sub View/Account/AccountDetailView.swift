//
//  AccountDetailView.swift
//  My Spot
//
//  Created by Isaac Paschall on 6/4/22.
//

import SwiftUI

struct AccountDetailView: View {
    
    @State var userid: String
    @State var accountModel: AccountModel?
    @State private var image: UIImage?
    @State private var name: String = "          " + "Account".localized() + "          "
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
    @State private var spots: [SpotFromCloud] = []
    @State private var linkDictionary: [String: URL] = [:]
    @State private var spotBadgeColor: Color = .gray
    @State private var downloadBadgeColor: Color = .gray
    @State private var badges: [String] = []
    @State private var tappedBadge = "flag"
    @State private var badgeNum = 0
    @State private var openSettings = false
    @State private var goToSettings = false
    @State private var isLoading = true
    @State private var isFetching = false
    @State private var presentShareSheet = false
    @State private var presentBadgeInfoAlert = false
    @State private var presentEditSheet = false
    @State private var presentNotificationSheet = false
    @State private var presentAccountCreation =  false
    @State private var didDelete = false
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    @EnvironmentObject var tabController: TabController
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    private var myAccount: Bool {
        cloudViewModel.userID == userid
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                if !isLoading {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        Task {
                            await pullRefresh()
                        }
                    }
                    VStack {
                        imageView
                        stats
                        links
                        bioView
                        badgeRow
                        mySpots
                    }
                    .navigationViewStyle(.stack)
                } else {
                    loadingAccountSpinner
                }
            }
            .coordinateSpace(name: "pullToRefresh")
            .fullScreenCover(isPresented: $presentAccountCreation) {
                Task {
                    await refreshAccount()
                }
            } content: {
                CreateAccountView(accountModel: nil)
            }
            .fullScreenCover(isPresented: $presentEditSheet) {
                Task {
                    await refreshAccount()
                }
            } content: {
                if let accountModel = accountModel {
                    CreateAccountView(accountModel: accountModel)
                }
            }
            .fullScreenCover(isPresented: $openSettings) {
                SettingsView()
            }
            .alert(badgeName().localized() + " " + "Badge".localized(), isPresented: $presentBadgeInfoAlert) {
                Button("OK".localized(), role: .cancel) { }
            } message: {
                Text(badgeMessage().localized())
            }
            .background(ShareViewController(isPresenting: $presentShareSheet) {
                let av = shareSheetAccount(userid: userid, name: name)
                av.completionWithItemsHandler = { _, _, _, _ in
                    presentShareSheet = false
                }
                return av
            })
            .onChange(of: UserDefaults.standard.integer(forKey: "badge")) { newValue in
                badgeNum = newValue
            }
            .onChange(of: didDelete) { deleted in
                if deleted {
                    Task {
                        await pullRefresh()
                        didDelete = false
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationViewStyle(.stack)
            .sheet(isPresented: $presentNotificationSheet) {
                if goToSettings == true {
                    goToSettings = false
                    openSettings = true
                }
            } content: {
                NotificationView(badgeNum: $badgeNum, goToSettings: $goToSettings)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    HStack {
                        shareButton
                        editButton
                    }
                }
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if myAccount {
                        settingsButton
                        notificationButton
                    } else {
                        adminButton
                        doneButton
                    }
                }
                ToolbarItem(placement: .principal) {
                    customNavigationTitle
                }
            }
            .onAppear {
                Task {
                    await inititalize()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    // MARK: - Sub Views
    
    private var customNavigationTitle: some View {
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
    
    private var doneButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Text("Done".localized())
        }
    }
    
    @ViewBuilder
    private var adminButton: some View {
        if cloudViewModel.userID == UserDefaultKeys.admin {
            Button {
                if let accountModel = accountModel {
                    Task {
                        try? await cloudViewModel.makeExplorer(id: accountModel.record.recordID)
                    }
                }
            } label: {
                Text("Pro")
            }
        }
    }
    
    private var notificationButton: some View {
        Button {
            presentNotificationSheet.toggle()
        } label: {
            Image(systemName: "bell")
        }
        .if(badgeNum > 0) { view in
            view.overlay {
                Badge(count: $badgeNum, color: .red)
            }
        }
    }
    
    private var settingsButton: some View {
        Button {
            openSettings.toggle()
        } label: {
            Image(systemName: "gear")
        }
    }
    
    @ViewBuilder
    private var editButton: some View {
        if myAccount && accountModel != nil {
            Button {
                presentEditSheet.toggle()
            } label: {
                Text("Edit".localized())
            }
        }
    }
    
    @ViewBuilder
    private var shareButton: some View {
        if UIDevice.current.userInterfaceIdiom != .pad {
            Button {
                if myAccount {
                    shareSheet(userid: userid, name: name)
                } else {
                    presentShareSheet = true
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
    
    @ViewBuilder
    private var mySpots: some View {
        if let accountModel = accountModel {
            LazyVStack(alignment: .leading, spacing: 0) {
                mySpotsList(accountModel: accountModel)
                if isFetching {
                    loadingSpotsSpinner
                } else {
                    paginationRow
                }
            }
        }
    }
    
    private var paginationRow: some View {
        Color.clear
            .task {
                if let cursor = cloudViewModel.cursorAccount, !isFetching, !spots.isEmpty {
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
    
    private var loadingSpotsSpinner: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .background { Color.clear }
    }
    
    private func mySpotsList(accountModel: AccountModel) -> some View {
        ForEach(spots.indices, id: \.self) { i in
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    NavigationLink {
                        DetailView(isSheet: false, from: Tab.profile, spot: spots[i], didDelete: $didDelete)
                    } label: {
                        MapSpotPreview(spot: $spots[i])
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .id(i)
                if i != spots.count - 1 {
                Divider()
                    .padding()
                }
            }
        }
        .animation(.default, value: spots)
    }
    
    private var badgeRow: some View {
        HStack {
            Text("Spots:")
                .font(.headline)
            Spacer()
            badgeView
        }
        .padding(.top, 5)
        .padding(.leading, 3)
    }
    
    @ViewBuilder
    private var bioView: some View {
        if let bio = bio {
            Text(bio)
                .frame(maxWidth: UIScreen.screenWidth * 0.6)
                .multilineTextAlignment(.center)
                .font(.callout)
                .padding(.top, 5)
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 130, height: 130)
                .clipShape(Circle())
                .padding(.bottom, 5)
        }
    }
    
    private var loadingAccountSpinner: some View {
        ProgressView("Loading Account".localized())
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
            }
    }
    
    private var badgeView: some View {
        HStack {
            ForEach(badges, id: \.self) { badge in
                Image(systemName: badge)
                    .padding(6)
                    .foregroundColor(badge == "mappin.and.ellipse" ? spotBadgeColor : (badge == "icloud.and.arrow.down" ? downloadBadgeColor : .white))
                    .background { Color.gray }
                    .clipShape(Circle())
                    .onTapGesture {
                        tappedBadge = badge
                        presentBadgeInfoAlert = true
                    }
                
            }
        }
    }
    
    private var downloadsCount: some View {
        VStack {
            Text("\(downloads)")
            Text("Downloads".localized())
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var spotsCount: some View {
        VStack {
            Text("\(spotCount)")
            Text("Spots")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private func seperator(geo: GeometryProxy) -> some View {
        Rectangle()
            .fill(colorScheme == .dark ? Color.gray : Color.black)
            .frame(width: 1, height: geo.size.height * 1.5, alignment: .center)
    }
    
    private var stats: some View {
        GeometryReader { geo in
            HStack(alignment: .center) {
                Spacer()
                downloadsCount
                seperator(geo: geo)
                spotsCount
                Spacer()
            }
        }
        .padding(.bottom, 30)
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
                        .background { colorScheme == .dark ? Color.gray : Color.white }
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func inititalize() async {
        if userid == "error" {
            userid = cloudViewModel.userID
        }
        do {
            let fetchedArr = try await cloudViewModel.getDownloadsAndSpots(from: userid)
            downloads = fetchedArr[0]
            spotCount = fetchedArr[1]
        } catch {
            print("failed to load spot count")
        }
        if accountModel == nil {
            do {
                accountModel = try await cloudViewModel.fetchAccount(userid: userid, withImage: true)
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
                } else {
                    enum account: Error {
                        case error
                    }
                    throw account.error
                }
            } catch {
                await checkToCreateAccount()
                bio = "Unable to load account".localized()
                print("failed to fetch account")
                print(error)
            }
        } else {
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
        }
        initializeBadgesAndLinks()
        withAnimation {
            isLoading = false
        }
        if spots.isEmpty {
            await fetchSpots()
        }
    }
    
    private func checkToCreateAccount() async {
        if cloudViewModel.isSignedInToiCloud {
            let doesAccountExist = await cloudViewModel.doesAccountExist(for: cloudViewModel.userID)
            if !doesAccountExist {
                presentAccountCreation.toggle()
            } else {
                try? await cloudViewModel.getMemberSince(fromid: cloudViewModel.userID)
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
    
    private func pullRefresh() async {
        await refreshAccount()
        do {
            let fetchedArr = try await cloudViewModel.getDownloadsAndSpots(from: userid)
            downloads = fetchedArr[0]
            spotCount = fetchedArr[1]
        } catch {
            print("failed to load spot count")
        }
        initializeBadgesAndLinks()
        await fetchSpots()
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
                linkDictionary["youtube"] = URL(string: "https://www.youtube.com/channel/" + youtube.replacingOccurrences(of: "@", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
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
        if userid == "error" {
            userid = cloudViewModel.userID
        }
        do {
            accountModel = try await cloudViewModel.fetchAccount(userid: userid, withImage: true)
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
    
    private func shareSheetAccount(userid: String, name: String) -> UIActivityViewController {
        return UIActivityViewController(activityItems: ["Check out, \"".localized() + name + "\" on My Spot! ".localized(), URL(string: "myspot://" + (userid)) ?? "", "\n\nIf you don't have My Spot, get it on the Appstore here: ".localized(), URL(string: "https://apps.apple.com/us/app/my-spot-exploration/id1613618373")!], applicationActivities: nil)
    }
    
    private func shareSheet(userid: String, name: String) {
        let activityView = shareSheetAccount(userid: userid, name: name)

        let allScenes = UIApplication.shared.connectedScenes
        let scene = allScenes.first { $0.activationState == .foregroundActive }

        if let windowScene = scene as? UIWindowScene {
            windowScene.keyWindow?.rootViewController?.present(activityView, animated: true, completion: nil)
        }

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
