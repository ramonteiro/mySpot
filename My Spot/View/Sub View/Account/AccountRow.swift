import SwiftUI

struct AccountRow: View {
    
    @State private var spots = 0
    @State private var downloads = 0
    @Binding var account: AccountModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    var body: some View {
        HStack {
            image
            content
            Spacer()
            downloadsAndSpots
        }
        .padding(.horizontal)
    }
    
    private var downloadsAndSpots: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "icloud.and.arrow.down")
                Text("\(downloads)")
            }
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text("\(spots)")
            }
        }
        .foregroundColor(.gray)
        .task {
            let spotsAndDownloadsArr = try? await cloudViewModel.getDownloadsAndSpots(from: account.id)
            if spotsAndDownloadsArr?.count == 2 {
                DispatchQueue.main.async {
                    downloads = spotsAndDownloadsArr?[0] ?? 0
                    spots = spotsAndDownloadsArr?[1] ?? 0
                }
            }
        }
    }
    
    @ViewBuilder
    private var image: some View {
        if let image = account.image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .onAppear {
                    cloudViewModel.checkForCompression(images: ["image"],
                                                       id: account.record.recordID.recordName)
                }
        } else {
            Color.gray
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .task {
                    account.image = await cloudViewModel.fetchAccountImage(userid: account.id)
                }
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading) {
            Text(account.name)
                .lineLimit(2)
            Text(account.pronouns ?? "")
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(.leading, 10)
    }
}
