import SwiftUI
import PhotosUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = AuthService.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var avatarImage: Image?
    @State private var isUploadingAvatar = false
    @State private var showFeedback = false
    @State private var showGoals = false
    @AppStorage("avatarUrl") private var avatarUrl = ""

    // Profile Flair
    @State private var bio: String = ""
    @State private var coolFact: String = ""
    @State private var profileDescription: String = ""
    @State private var isEditingFlair = false
    @State private var isSavingFlair = false
    @State private var flairLoaded = false

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

                    // Profile Flair Section
                    flairSection

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
                        NavigationLink {
                            TrophiesView()
                        } label: {
                            ProfileRow(icon: "trophy.fill", title: "Trophies", color: Color(red: 255/255, green: 215/255, blue: 0/255))
                        }
                        Divider().foregroundStyle(Color.agonBorder)
                        NavigationLink {
                            RivalsView()
                        } label: {
                            ProfileRow(icon: "figure.fencing", title: "Rivals", color: Color.agonAccent)
                        }
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "heart.fill", title: "Connected Apps", color: Color.agonAccent)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "bell.fill", title: "Notifications", color: Color.agonSecondary)
                        Divider().foregroundStyle(Color.agonBorder)
                        Button { showGoals = true } label: {
                            ProfileRow(icon: "target", title: "Goals", color: Color.agonAccent)
                        }
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
            .sheet(isPresented: $showGoals) {
                GoalsView()
            }
            .task {
                await loadFlairFromProfile()
            }
        }
    }

    // MARK: - Flair Section

    private var flairSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.agonAccent)
                Text("About Me")
                    .font(.headline)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
                Button {
                    if isEditingFlair {
                        Task { await saveFlair() }
                    } else {
                        isEditingFlair = true
                    }
                } label: {
                    if isSavingFlair {
                        ProgressView()
                    } else {
                        Text(isEditingFlair ? "Save" : "Edit")
                            .font(.caption.bold())
                            .foregroundStyle(Color.agonAccent)
                    }
                }
            }

            if isEditingFlair {
                VStack(spacing: 10) {
                    flairField(label: "Bio", text: $bio, placeholder: "Tell people about yourself...")
                    flairField(label: "Cool Fact", text: $coolFact, placeholder: "Something interesting about you...")
                    flairField(label: "Health Goals", text: $profileDescription, placeholder: "What are your fitness goals?")
                }
            } else {
                if bio.isEmpty && coolFact.isEmpty && profileDescription.isEmpty {
                    Text("Tap Edit to add your bio, cool fact, and description")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        if !bio.isEmpty {
                            flairDisplay(label: "Bio", value: bio)
                        }
                        if !coolFact.isEmpty {
                            flairDisplay(label: "Cool Fact", value: coolFact)
                        }
                        if !profileDescription.isEmpty {
                            flairDisplay(label: "Description", value: profileDescription)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func flairField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(Color.agonTextSecondary)
            TextField(placeholder, text: text, axis: .vertical)
                .font(.subheadline)
                .padding(8)
                .background(Color.agonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .lineLimit(3)
        }
    }

    private func flairDisplay(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(Color.agonTextSecondary)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
        }
    }

    // MARK: - Flair API

    private func loadFlairFromProfile() async {
        guard !flairLoaded else { return }
        do {
            if let profile = try await APIService.shared.getProfile() {
                bio = profile["bio"] as? String ?? ""
                coolFact = profile["coolFact"] as? String ?? ""
                profileDescription = profile["description"] as? String ?? ""
                flairLoaded = true
            }
        } catch {
            print("Load flair error: \(error)")
        }
    }

    private func saveFlair() async {
        isSavingFlair = true
        do {
            try await APIService.shared.updateProfileFlair(
                bio: bio.isEmpty ? nil : bio,
                coolFact: coolFact.isEmpty ? nil : coolFact,
                description: profileDescription.isEmpty ? nil : profileDescription
            )
            isEditingFlair = false
        } catch {
            print("Save flair error: \(error)")
        }
        isSavingFlair = false
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
