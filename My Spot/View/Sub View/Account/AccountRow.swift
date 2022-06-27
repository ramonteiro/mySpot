import SwiftUI

struct AccountRow: View {
    
    @Binding var account: AccountModel
    @EnvironmentObject var cloudViewModel: CloudKitViewModel
    
    var body: some View {
        HStack {
            image
            content
            Spacer()
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var image: some View {
        if let image = account.image {
            Image(uiImage: image)
                .resizable()
                .frame(width: 60, height: 60)
                .clipShape(Circle())
        } else {
            Image(uiImage: defaultImages.errorAccount!)
                .resizable()
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
            Text(account.pronouns ?? "")
                .foregroundColor(.gray)
        }
        .padding(.leading, 10)
    }
}
