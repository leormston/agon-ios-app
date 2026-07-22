import SwiftUI

struct CommunityView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Leaderboard
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("This Week's Leaderboard")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }

                    LeaderboardRow(rank: 1, name: "Sarah M.", points: 2_450, isCurrentUser: false)
                    LeaderboardRow(rank: 2, name: "You", points: 2_180, isCurrentUser: true)
                    LeaderboardRow(rank: 3, name: "James K.", points: 1_920, isCurrentUser: false)
                    LeaderboardRow(rank: 4, name: "Priya R.", points: 1_845, isCurrentUser: false)
                    LeaderboardRow(rank: 5, name: "Tom W.", points: 1_670, isCurrentUser: false)
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Friends Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Friends Activity")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    ActivityFeedItem(name: "Sarah M.", action: "completed a 5K run", time: "2h ago")
                    ActivityFeedItem(name: "James K.", action: "hit their step goal", time: "4h ago")
                    ActivityFeedItem(name: "Priya R.", action: "started a new challenge", time: "6h ago")
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.agonBackground)
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

            Text("\(points) pts")
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
