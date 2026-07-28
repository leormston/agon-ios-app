import SwiftUI

struct GoalsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("goal_steps") private var stepsGoal: Double = 10_000
    @AppStorage("goal_exerciseMinutes") private var exerciseGoal: Double = 30
    @AppStorage("goal_distanceWalked") private var distanceGoal: Double = 5.0
    @AppStorage("goal_totalSleep") private var sleepGoal: Double = 8.0
    @AppStorage("goal_timeInDaylight") private var daylightGoal: Double = 60
    @AppStorage("goal_distanceRan") private var distanceRanGoal: Double = 3.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Set your daily targets. These appear as goal lines on your charts.")
                        .font(.subheadline)
                        .foregroundStyle(Color.agonTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 4)

                    GoalRow(icon: "figure.walk", title: "Steps", value: $stepsGoal, unit: "steps", step: 1000, range: 1000...50000)
                    GoalRow(icon: "flame.fill", title: "Exercise", value: $exerciseGoal, unit: "min", step: 5, range: 5...180)
                    GoalRow(icon: "figure.walk.motion", title: "Distance Walked", value: $distanceGoal, unit: "km", step: 0.5, range: 1...30)
                    GoalRow(icon: "figure.run", title: "Distance Ran", value: $distanceRanGoal, unit: "km", step: 0.5, range: 0.5...30)
                    GoalRow(icon: "moon.fill", title: "Sleep", value: $sleepGoal, unit: "hrs", step: 0.5, range: 4...12)
                    GoalRow(icon: "sun.max.fill", title: "Daylight", value: $daylightGoal, unit: "min", step: 10, range: 10...300)
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.agonAccent)
                }
            }
        }
    }
}

struct GoalRow: View {
    let icon: String
    let title: String
    @Binding var value: Double
    let unit: String
    let step: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.agonAccent)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
                Text(formattedValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.agonAccent)
            }

            HStack(spacing: 12) {
                Button {
                    if value - step >= range.lowerBound {
                        value -= step
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.agonTextSecondary)
                }

                Slider(value: $value, in: range, step: step)
                    .tint(Color.agonAccent)

                Button {
                    if value + step <= range.upperBound {
                        value += step
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.agonAccent)
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var formattedValue: String {
        if step >= 1 {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f \(unit)", value)
    }
}

#Preview {
    GoalsView()
}
