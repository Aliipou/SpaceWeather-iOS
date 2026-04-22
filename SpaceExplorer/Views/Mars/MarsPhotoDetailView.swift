import SwiftUI

struct MarsPhotoDetailView: View {
    let photo: MarsPhoto
    @State private var showFullScreen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CachedAsyncImage(url: photo.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onTapGesture { showFullScreen = true }
                } placeholder: {
                    ImageShimmer().frame(height: 300)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 14) {
                    infoRow("Rover", value: photo.rover.name, icon: "car.fill")
                    infoRow("Camera", value: photo.camera.fullName, icon: "camera")
                    infoRow("Sol", value: "\(photo.sol)", icon: "sun.max")
                    infoRow("Earth Date", value: photo.formattedEarthDate, icon: "calendar")
                    infoRow("Photo ID", value: "#\(photo.id)", icon: "number")
                }
                .padding(16)
                .spaceCard()
            }
            .padding(16)
        }
        .background(SpaceTheme.background)
        .navigationTitle(photo.camera.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFullScreen) {
            if let url = photo.imageURL {
                FullScreenImageView(url: url, isPresented: $showFullScreen)
                    .ignoresSafeArea()
            }
        }
    }

    private func infoRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(SpaceTheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(SpaceTheme.captionFont())
                    .foregroundStyle(SpaceTheme.textSecondary)
                Text(value)
                    .font(SpaceTheme.bodyFont())
                    .foregroundStyle(SpaceTheme.textPrimary)
            }
        }
    }
}
