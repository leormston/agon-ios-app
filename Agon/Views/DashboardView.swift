import SwiftUI

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good morning 👋")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Your Health Today")
                            .font(.title.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Metric Cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    MetricCard(title: "Steps", value: "8,432", icon: "figure.walk", color: Color.agonAccent)
                    MetricCard(title: "Calories", value: "1,847", icon: "flame", color: Color.agonSecondary)
                    MetricCard(title: "Sleep", value: "7h 23m", icon: "moon.fill", color: Color.agonTextSecondary)
                    MetricCard(title: "Heart Rate", value: "72 bpm", icon: "heart.fill", color: Color.agonAccent)
                }
                .padding(.horizontal)

                // Active Challenge Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Challenge")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("10K Steps Daily")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.agonTextPrimary)
                            Text("3 days remaining")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        Spacer()
                        CircularProgressView(progress: 0.84)
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.agonBackground)
    }
}

// MARK: - Components

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(Color.agonTextPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Color.agonTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.agonAccentTint, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.agonAccent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.bold())
                .foregroundStyle(Color.agonTextPrimary)
        }
        .frame(width: 50, height: 50)
    }
}

#Preview {
    DashboardView()
}
