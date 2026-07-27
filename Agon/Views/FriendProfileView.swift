import SwiftUI

struct FriendProfileView: View {
    let userId: String
    let displayName: String

    @State private var profile: [String: Any]?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // Avatar & Name
                    VStack(spacing: 12) {
                        avatarView
                            .frame(width: 80, height: 80)

                        Text(profileDisplayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.agonTextPrimary)

                        if let memberSince = memberSinceText {
                            Text("Member since \(memberSince)")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Active Challenges
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Active Challenges")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                        Spacer()
                        Text("\(activeChallengesCount)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.agonAccent)
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Today's Health Summary
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.agonAccent)
                            Text("Today's Health")
                                .font(.headline)
                                .foregroundStyle(Color.agonTextPrimary)
                        }

                        if hasHealthData {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                healthStat(icon: "figure.walk", label: "Steps", value: stepsText)
                                healthStat(icon: "flame.fill", label: "Exercise", value: exerciseText)
                                healthStat(icon: "figure.walk.motion", label: "Distance", value: distanceText)
                            }
                        } else {
                            Text("No health data available")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = profile?["avatarUrl"] as? String, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                initialCircle
            }
            .clipShape(Circle())
        } else {
            initialCircle
        }
    }

    private var initialCircle: some View {
        Circle()
            .fill(Color.agonAccent.opacity(0.2))
            .overlay {
                Text(String(profileDisplayName.prefix(1)).uppercased())
                    .font(.title.bold())
                    .foregroundStyle(Color.agonAccent)
            }
    }

    // MARK: - Health Stat View

    private func healthStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.agonAccent)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Computed Properties

    private var profileDisplayName: String {
        (profile?["displayName"] as? String) ?? displayName
    }

    private var memberSinceText: String? {
        guard let createdAt = profile?["createdAt"] as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: createdAt)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: createdAt)
        }
        guard let parsedDate = date else { return nil }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM yyyy"
        return displayFormatter.string(from: parsedDate)
    }

    private var activeChallengesCount: Int {
        (profile?["activeChallengesCount"] as? Int) ?? 0
    }

    private var latestSnapshot: [String: Any]? {
        if let snapshots = profile?["recentSnapshots"] as? [[String: Any]], let first = snapshots.first {
            return first["metrics"] as? [String: Any] ?? first
        }
        return nil
    }

    private var hasHealthData: Bool {
        latestSnapshot != nil
    }

    private var stepsText: String {
        guard let snapshot = latestSnapshot else { return "—" }
        if let steps = snapshot["steps"] as? Double {
            return Int(steps).formatted(.number)
        }
        if let steps = snapshot["steps"] as? Int {
            return steps.formatted(.number)
        }
        return "—"
    }

    private var exerciseText: String {
        guard let snapshot = latestSnapshot else { return "—" }
        if let minutes = snapshot["exerciseMinutes"] as? Double {
            return "\(Int(minutes)) min"
        }
        if let minutes = snapshot["exerciseMinutes"] as? Int {
            return "\(minutes) min"
        }
        return "—"
    }

    private var distanceText: String {
        guard let snapshot = latestSnapshot else { return "—" }
        let walked = (snapshot["distanceWalked"] as? Double) ?? 0
        let ran = (snapshot["distanceRan"] as? Double) ?? 0
        let total = walked + ran
        if total > 0 {
            return String(format: "%.1f km", total)
        }
        return "—"
    }

    // MARK: - Load

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await APIService.shared.getUserProfile(userId: userId)
            if profile == nil {
                errorMessage = "Profile not found"
            }
        } catch {
            errorMessage = "Failed to load profile"
            print("Load profile error: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        FriendProfileView(userId: "test-user-id", displayName: "John")
    }
}
