import SwiftUI

struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // AI Insight Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundStyle(Color.agonAccent)
                            Text("AI Insight")
                                .font(.headline)
                                .foregroundStyle(Color.agonTextPrimary)
                        }

                        Text("Your sleep quality improves by 23% on days you exercise before 6pm. Consider shifting your evening workouts earlier.")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.agonAccentTint.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Weekly Summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Summary")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        InsightRow(icon: "figure.walk", title: "Activity", detail: "12% more active than last week", trend: .up)
                        InsightRow(icon: "moon.fill", title: "Sleep", detail: "Avg 7.2 hours - on target", trend: .stable)
                        InsightRow(icon: "heart.fill", title: "Heart Health", detail: "Resting HR down 3 bpm", trend: .up)
                        InsightRow(icon: "fork.knife", title: "Nutrition", detail: "Calorie goal missed 2 days", trend: .down)
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommendations")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)

                        RecommendationRow(text: "Add a 10-minute walk after lunch", icon: "figure.walk")
                        RecommendationRow(text: "Try a consistent bedtime this week", icon: "bed.double.fill")
                        RecommendationRow(text: "Increase daily water intake", icon: "drop.fill")
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Insights")
        }
    }
}

enum Trend {
    case up, down, stable
}

struct InsightRow: View {
    let icon: String
    let title: String
    let detail: String
    let trend: Trend

    var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    var trendColor: Color {
        switch trend {
        case .up: return Color.agonAccent
        case .down: return Color.agonAccentPressed
        case .stable: return Color.agonSecondary
        }
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(Color.agonSecondary)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.agonTextPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color.agonTextSecondary)
            }
            Spacer()
            Image(systemName: trendIcon)
                .foregroundStyle(trendColor)
        }
    }
}

struct RecommendationRow: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.agonAccent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
            Spacer()
        }
    }
}

#Preview {
    InsightsView()
}
