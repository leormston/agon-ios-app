import SwiftUI

struct ChallengesView: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showCreateChallenge = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Create Challenge Button
                Button {
                    showCreateChallenge = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Challenge")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.agonAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Active Challenges
                SectionHeader(title: "Active Challenges", icon: "flame.fill")

                if viewModel.isLoading && viewModel.activeChallenges.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else if viewModel.activeChallenges.isEmpty {
                    EmptyStateCard(
                        icon: "trophy",
                        message: "No active challenges yet",
                        subtitle: "Create one to get started!"
                    )
                } else {
                    ForEach(viewModel.activeChallenges) { challenge in
                        NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                            ActiveChallengeCard(challenge: challenge)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Invited Challenges
                if !viewModel.invitedChallenges.isEmpty {
                    SectionHeader(title: "Join a Challenge", icon: "plus.circle.fill")

                    ForEach(viewModel.invitedChallenges) { challenge in
                        InvitedChallengeCard(challenge: challenge) {
                            Task {
                                await viewModel.joinChallenge(challenge)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadChallenges()
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView(viewModel: viewModel)
        }
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let metric = challenge.metricType {
                            Image(systemName: metric.icon)
                                .foregroundStyle(Color.agonAccent)
                        }
                        Text(challenge.metricType?.title ?? challenge.metric)
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Text("\(challenge.participants.count) participants • \(challenge.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
                CircularProgressView(progress: progressForChallenge(challenge))
            }

            ProgressView(value: progressForChallenge(challenge))
                .tint(Color.agonAccent)
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressForChallenge(_ challenge: Challenge) -> Double {
        // Calculate time-based progress
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let start = formatter.date(from: challenge.startDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.startDate) ?? Date()
        }()

        let end = formatter.date(from: challenge.endDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.endDate) ?? Date()
        }()

        let totalDuration = end.timeIntervalSince(start)
        guard totalDuration > 0 else { return 0 }

        let elapsed = Date().timeIntervalSince(start)
        return min(1.0, max(0, elapsed / totalDuration))
    }
}

// MARK: - Invited Challenge Card

struct InvitedChallengeCard: View {
    let challenge: Challenge
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let metric = challenge.metricType {
                            Image(systemName: metric.icon)
                                .foregroundStyle(Color.agonAccent)
                        }
                        Text(challenge.metricType?.title ?? challenge.metric)
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Text("\(challenge.participants.count) participants • \(challenge.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
                Button(action: onJoin) {
                    Text("Join")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.agonAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let message: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.agonTextSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.agonAccent)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.agonTextPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ChallengesView()
    }
}
