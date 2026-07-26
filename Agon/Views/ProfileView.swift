import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var isUploadingAvatar = false
    @State private var showFeedback = false
    @AppStorage("avatarUrl") private var avatarUrl = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar and Name
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                if let avatarImage {
                                    avatarImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else if !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.agonAccent.gradient)
                                            .overlay {
                                                Text(userInitial)
                                                    .font(.largeTitle.bold())
                                                    .foregroundStyle(.white)
                                            }
                                    }
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.agonAccent.gradient)
                                        .frame(width: 80, height: 80)
                                        .overlay {
                                            Text(userInitial)
                                                .font(.largeTitle.bold())
                                                .foregroundStyle(.white)
                                        }
                                }

                                // Camera badge
                                Circle()
                                    .fill(Color.agonSurface)
                                    .frame(width: 26, height: 26)
                                    .overlay {
                                        Image(systemName: "camera.fill")
                                            .font(.caption2)
                                            .foregroundStyle(Color.agonTextPrimary)
                                    }
                                    .shadow(radius: 2)
                            }
                        }

                        if isUploadingAvatar {
                            ProgressView("Uploading...")
                                .font(.caption)
                        }

                        Text(displayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                        
                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                    }
                    .padding(.top)

                    // Stats
                    HStack(spacing: 0) {
                        StatItem(value: "-", label: "Day Streak")
                        StatItem(value: "-", label: "Challenges")
                        StatItem(value: "-", label: "Wins")
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Settings Sections
                    VStack(spacing: 0) {
                        ProfileRow(icon: "heart.fill", title: "Connected Apps", color: Color.agonAccent)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "bell.fill", title: "Notifications", color: Color.agonSecondary)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "target", title: "Goals", color: Color.agonAccent)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "lock.fill", title: "Privacy", color: Color.agonSecondary)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "questionmark.circle.fill", title: "Help & Support", color: Color.agonTextSecondary)
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Feedback
                    Button {
                        showFeedback = true
                    } label: {
                        HStack {
                            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                                .foregroundStyle(Color.agonAccent)
                                .frame(width: 28)
                            Text("Report Bug / Request Feature")
                                .font(.subheadline)
                                .foregroundStyle(Color.agonTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        .padding()
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Sign Out
                    Button {
                        authService.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.agonAccent)
                }
            }
            .onChange(of: selectedPhoto) {
                Task {
                    await handlePhotoSelection()
                }
            }
            .sheet(isPresented: $showFeedback) {
                FeedbackView()
            }
        }
    }

    private func handlePhotoSelection() async {
        guard let selectedPhoto else { return }

        isUploadingAvatar = true

        do {
            // Load the image data
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                isUploadingAvatar = false
                return
            }

            // Compress to JPEG
            guard let uiImage = UIImage(data: data),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.7) else {
                isUploadingAvatar = false
                return
            }

            // Show preview immediately
            avatarImage = Image(uiImage: uiImage)

            // Get presigned URL from backend
            let urls = try await APIService.shared.getAvatarUploadUrl()

            // Upload to S3
            try await APIService.shared.uploadImageToS3(presignedUrl: urls.uploadUrl, imageData: jpegData)

            // Save URL locally
            avatarUrl = urls.avatarUrl

        } catch {
            print("Avatar upload failed: \(error)")
        }

        isUploadingAvatar = false
    }

    private var userInitial: String {
        let name = authService.currentUser?.displayName ?? "U"
        return String(name.prefix(1)).uppercased()
    }

    private var displayName: String {
        authService.currentUser?.displayName ?? "User"
    }

}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.agonAccent)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}

make 
