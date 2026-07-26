import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @State private var scores: [(name: String, score: Int, isCurrentUser: Bool)] = []
    @State private var isLoading = true

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
                            HStack {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .frame(width: 24)
                                    .foregroundStyle(index < 3 ? Color.agonAccent : Color.agonTextSecondary)

                                Circle()
                                    .fill(entry.isCurrentUser ? Color.agonAccent : Color.agonBorder)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text(String(entry.name.prefix(1)))
                                            .font(.caption.bold())
                                            .foregroundStyle(entry.isCurrentUser ? .white : Color.agonTextPrimary)
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
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadScores()
        }
    }

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
                        isCurrentUser: (p["userId"] as? String) == currentUserId
                    )
                }
            }
        } catch {
            print("Failed to load challenge scores: \(error)")
        }
        isLoading = false
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
