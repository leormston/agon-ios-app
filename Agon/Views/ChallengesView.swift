import SwiftUI

struct ChallengesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Active Challenges
                SectionHeader(title: "Active Challenges", icon: "flame.fill")

                ChallengeCard(
                    title: "10K Steps Daily",
                    participants: 5,
                    daysLeft: 3,
                    progress: 0.84,
                    color: Color.agonAccent
                )

                ChallengeCard(
                    title: "Sleep 8 Hours",
                    participants: 3,
                    daysLeft: 7,
                    progress: 0.45,
                    color: Color.agonSecondary
                )

                // Available Challenges
                SectionHeader(title: "Join a Challenge", icon: "plus.circle.fill")

                ChallengeCard(
                    title: "Run 50km This Week",
                    participants: 12,
                    daysLeft: 7,
                    progress: 0,
                    color: Color.agonAccent
                )

                ChallengeCard(
                    title: "Mindfulness Streak",
                    participants: 8,
                    daysLeft: 14,
                    progress: 0,
                    color: Color.agonSecondary
                )
            }
            .padding()
        }
        .background(Color.agonBackground)
    }
}

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

struct ChallengeCard: View {
    let title: String
    let participants: Int
    let daysLeft: Int
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)
                    Text("\(participants) participants • \(daysLeft) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
                if progress > 0 {
                    CircularProgressView(progress: progress)
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(color)
                }
            }

            if progress > 0 {
                ProgressView(value: progress)
                    .tint(color)
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ChallengesView()
}
