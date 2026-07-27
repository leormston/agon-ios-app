import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @Environment(\.dismiss) private var dismiss
    @State private var scores: [(name: String, score: Int, isCurrentUser: Bool, avatarUrl: String?, userId: String)] = []
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var showLeaveConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private var isCreator: Bool {
        let currentUserId = AuthService.shared.currentUser?.id ?? ""
        return challenge.creatorId == currentUserId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    if let metric = challenge.metricType {
                        Image(systemName: metric.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(Color.agonAccent)
                    }

                    Text(challenge.metricType?.title ?? challenge.metric)
                        .font(.title2.bold())
                        .foregroundStyle(Color.agonTextPrimary)

                    Text("\(challenge.daysRemaining) days remaining")
                        .font(.subheadline)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Info
                VStack(spacing: 0) {
                    InfoRow(label: "Metric", value: challenge.metricType?.title ?? challenge.metric)
                    Divider().foregroundStyle(Color.agonBorder)
                    InfoRow(label: "Duration", value: durationText)
                    Divider().foregroundStyle(Color.agonBorder)
                    InfoRow(label: "Participants", value: "\(challenge.participants.count)")
                    Divider().foregroundStyle(Color.agonBorder)
                    InfoRow(label: "Status", value: challenge.status.capitalized)
                }
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Leaderboard
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Leaderboard")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if scores.isEmpty {
                        Text("No scores yet - sync your health data!")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                            .padding()
                    } else {
                        ForEach(Array(scores.enumerated()), id: \.offset) { index, entry in
                            NavigationLink(destination: FriendProfileView(userId: entry.userId, displayName: entry.name)) {
                                leaderboardRow(index: index, entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                // Delete / Leave Button
                if isCreator {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "trash")
                            }
                            Text("Delete Challenge")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isProcessing)
                } else {
                    Button {
                        showLeaveConfirmation = true
                    } label: {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                            }
                            Text("Leave Challenge")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.agonSurface)
                        .foregroundStyle(Color.agonTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.agonBorder, lineWidth: 1)
                        )
                    }
                    .disabled(isProcessing)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadScores()
        }
        .alert("Delete Challenge", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteChallenge() }
            }
        } message: {
            Text("Are you sure you want to delete this challenge? This cannot be undone.")
        }
        .alert("Leave Challenge", isPresented: $showLeaveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                Task { await leaveChallenge() }
            }
        } message: {
            Text("Are you sure you want to leave this challenge?")
        }
    }

    // MARK: - Leaderboard Row

    @ViewBuilder
    private func leaderboardRow(index: Int, entry: (name: String, score: Int, isCurrentUser: Bool, avatarUrl: String?, userId: String)) -> some View {
        HStack {
            Text("\(index + 1)")
                .font(.headline)
                .frame(width: 24)
                .foregroundStyle(index < 3 ? Color.agonAccent : Color.agonTextSecondary)

            if let avatarUrl = entry.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(entry.isCurrentUser ? Color.agonAccent : Color.agonBorder)
                        .overlay {
                            Text(String(entry.name.prefix(1)))
                                .font(.caption.bold())
                                .foregroundStyle(entry.isCurrentUser ? .white : Color.agonTextPrimary)
                        }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(entry.isCurrentUser ? Color.agonAccent : Color.agonBorder)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(entry.name.prefix(1)))
                            .font(.caption.bold())
                            .foregroundStyle(entry.isCurrentUser ? .white : Color.agonTextPrimary)
                    }
            }

            Text(entry.name)
                .font(.subheadline)
                .bold(entry.isCurrentUser)
                .foregroundStyle(Color.agonTextPrimary)

            Spacer()

            Text("\(entry.score) \(challenge.metricType?.unit ?? "")")
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private var durationText: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let start = formatter.date(from: challenge.startDate) ?? Date()
        let end = formatter.date(from: challenge.endDate) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        if days <= 1 { return "1 Day" }
        if days <= 7 { return "1 Week" }
        return "1 Month"
    }

    private func loadScores() async {
        do {
            guard let data = try await APIService.shared.getChallengeDetails(challengeId: challenge.id) else {
                isLoading = false
                return
            }

            if let participants = data["scores"] as? [[String: Any]] {
                let currentUserId = AuthService.shared.currentUser?.id ?? ""
                scores = participants.map { p in
                    (
                        name: p["displayName"] as? String ?? "User",
                        score: p["score"] as? Int ?? 0,
                        isCurrentUser: (p["userId"] as? String) == currentUserId,
                        avatarUrl: p["avatarUrl"] as? String,
                        userId: p["userId"] as? String ?? ""
                    )
                }
            }
        } catch {
            print("Failed to load challenge scores: \(error)")
        }
        isLoading = false
    }

    private func deleteChallenge() async {
        isProcessing = true
        errorMessage = nil

        do {
            try await APIService.shared.deleteChallenge(challengeId: challenge.id)
            dismiss()
        } catch {
            errorMessage = "Failed to delete challenge. Please try again."
        }

        isProcessing = false
    }

    private func leaveChallenge() async {
        isProcessing = true
        errorMessage = nil

        do {
            try await APIService.shared.leaveChallenge(challengeId: challenge.id)
            dismiss()
        } catch {
            errorMessage = "Failed to leave challenge. Please try again."
        }

        isProcessing = false
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.agonTextPrimary)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ChallengeDetailView(challenge: Challenge(
            id: "test",
            creatorId: "user1",
            metric: "steps",
            startDate: "2026-07-26T00:00:00.000Z",
            endDate: "2026-08-02T00:00:00.000Z",
            status: "active",
            participants: ["user1"],
            createdAt: "2026-07-26T00:00:00.000Z"
        ))
    }
}
