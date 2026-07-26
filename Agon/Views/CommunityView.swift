import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = LeaderboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Leaderboard
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Today's Leaderboard")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }

                    if viewModel.entries.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 8) {
                            Image(systemName: "person.3")
                                .font(.title)
                                .foregroundStyle(Color.agonTextSecondary)
                            Text("No participants yet today")
                                .font(.subheadline)
                                .foregroundStyle(Color.agonTextSecondary)
                            Text("Your health data will appear here once synced")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        ForEach(viewModel.entries) { entry in
                            LeaderboardRow(
                                rank: entry.rank,
                                name: entry.displayName,
                                points: entry.score,
                                isCurrentUser: entry.isCurrentUser
                            )
                        }
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Friends Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Friends Activity")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    if viewModel.entries.isEmpty {
                        Text("Activity will show here once friends join")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    } else {
                        ForEach(viewModel.entries.prefix(3)) { entry in
                            ActivityFeedItem(
                                name: entry.displayName,
                                action: "logged \(entry.score.formatted()) steps today",
                                time: "Today"
                            )
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
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadLeaderboard()
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let points: Int
    let isCurrentUser: Bool

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.headline)
                .frame(width: 24)
                .foregroundStyle(rank <= 3 ? Color.agonAccent : Color.agonTextSecondary)

            Circle()
                .fill(isCurrentUser ? Color.agonAccent : Color.agonBorder)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(.caption.bold())
                        .foregroundStyle(isCurrentUser ? Color.white : Color.agonTextPrimary)
                }

            Text(name)
                .font(.subheadline)
                .bold(isCurrentUser)
                .foregroundStyle(Color.agonTextPrimary)

            Spacer()

            Text("\(points.formatted()) steps")
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct ActivityFeedItem: View {
    let name: String
    let action: String
    let time: String

    var body: some View {
        HStack(alignment: .top) {
            Circle()
                .fill(Color.agonBorder)
                .frame(width: 28, height: 28)
                .overlay {
                    Text(String(name.prefix(1)))
                        .font(.caption2.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.caption.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text(action)
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Text(time)
                    .font(.caption2)
                    .foregroundStyle(Color.agonTextSecondary)
            }
            Spacer()
        }
    }
}

#Preview {
    CommunityView()
}
