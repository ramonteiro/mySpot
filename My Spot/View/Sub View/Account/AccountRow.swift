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
    
    private var image: some View {
        Image(uiImage: account.image ?? defaultImages.errorAccount!)
            .resizable()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .task {
                if account.image == nil {
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
