import SwiftUI

struct SpotRowDemo<T: SpotPreviewType>: View {
    
    @Binding var spot: T
    var isShared: Bool?
    private var scope: String {
        if spot.isPublicPreview { return "Public".localized() }
        else { return "Private".localized() }
    }
    private var tags: [String] {
        spot.tagsPreview.components(separatedBy: ", ")
    }
    @State private var distance: String = ""
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var mapViewModel: MapViewModel
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                image
                details
            }
            .onAppear {
                initializeValues()
            }
            Spacer()
        }
    }

    // MARK: - Sub Views
    
    private var details: some View {
        HStack {
            VStack(alignment: .leading) {
                downloadsOrScope
                name
                locationName
                distanceAway
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var downloadsOrScope: some View {
        if spot.isFromDiscover {
            HStack(alignment: .center) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                Text("\(spot.downloadsPreview)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        } else {
            HStack(alignment: .center) {
                Image(systemName: "globe")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                Text("\(scope)")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
            }
        }
    }
    
    private var name: some View {
        Text(spot.namePreview)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .font(.headline)
            .fontWeight(.bold)
            .lineLimit(1)
    }
    
    private var image: some View {
        Image(uiImage: (spot.imagePreview ?? UIImage(systemName: "exclamationmark.triangle.fill"))!)
            .resizable()
            .scaledToFill()
            .frame(width: UIScreen.screenWidth - 50, height: 200)
            .cornerRadius(40)
    }
    
    @ViewBuilder
    private var locationName: some View {
        if !spot.locationNamePreview.isEmpty {
            HStack(alignment: .center) {
                Image(systemName: (spot.customLocationPreview ? "mappin" : "figure.wave"))
                    .foregroundColor(Color.gray)
                    .font(.subheadline)
                Text(spot.locationNamePreview)
                    .foregroundColor(Color.gray)
                    .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    private var distanceAway: some View {
        if !distance.isEmpty {
            Text((distance) + " away".localized())
                .foregroundColor(Color.gray)
                .font(.subheadline)
        }
    }

    // MARK: - Functions

    private func initializeValues() {
        if (mapViewModel.isAuthorized) {
            distance = mapViewModel.calculateDistance(from: spot.locationPreview)
        }
    }
}
