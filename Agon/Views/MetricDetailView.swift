import SwiftUI
import Charts

struct MetricDetailView: View {
    let metricType: HealthMetricType
    let snapshots: [DailySnapshot]
    let periodTitle: String

    @State private var selectedPoint: ChartPoint?
    @State private var showBarChart = false
    @State private var showFriendOverlay = false
    @State private var animateChart = false

    @AppStorage("goal_steps") private var stepsGoal: Double = 10_000
    @AppStorage("goal_exerciseMinutes") private var exerciseGoal: Double = 30
    @AppStorage("goal_distanceWalked") private var distanceGoal: Double = 5.0
    @AppStorage("goal_totalSleep") private var sleepGoal: Double = 8.0
    @AppStorage("goal_timeInDaylight") private var daylightGoal: Double = 60
    @AppStorage("goal_distanceRan") private var distanceRanGoal: Double = 3.0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with trend
                headerSection

                // Chart type toggle
                chartToggle

                // Main Chart
                chartSection

                // Streak
                streakSection

                // Summary Stats
                summarySection
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle(metricType.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: metricType.icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.agonAccent)
            Text(metricType.title)
                .font(.title2.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text(periodTitle)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)

            // Day-over-day trend
            if let trend = dayOverDayTrend {
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%+.1f%% vs yesterday", trend))
                        .font(.caption.bold())
                }
                .foregroundStyle(trend >= 0 ? Color.agonAccent : Color.agonTextSecondary)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chart Toggle

    private var chartToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation { showBarChart = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Line")
                }
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(!showBarChart ? Color.agonAccent : Color.clear)
                .foregroundStyle(!showBarChart ? .white : Color.agonTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Button {
                withAnimation { showBarChart = true }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                    Text("Bar")
                }
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(showBarChart ? Color.agonAccent : Color.clear)
                .foregroundStyle(showBarChart ? .white : Color.agonTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Breakdown")
                    .font(.headline)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
            }

            // Goal and Average info
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Rectangle()
                        .stroke(Color.agonSecondary, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                        .frame(width: 14, height: 2)
                    Text("Avg: \(formatValue(average))")
                        .font(.caption)
                        .foregroundStyle(Color.agonSecondary)
                }
                if let goal = goalForMetric {
                    HStack(spacing: 4) {
                        Rectangle()
                            .stroke(Color.agonAccent, style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                            .frame(width: 14, height: 2)
                        Text("Goal: \(formatValue(goal))")
                            .font(.caption)
                            .foregroundStyle(Color.agonAccent)
                    }
                }
                Spacer()
            }

            if chartData.isEmpty {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(Color.agonTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    if showBarChart {
                        barChartContent
                    } else {
                        lineChartContent
                    }

                    // Average line
                    RuleMark(y: .value("Average", average))
                        .foregroundStyle(Color.agonSecondary.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Avg")
                                .font(.caption2)
                                .foregroundStyle(Color.agonSecondary)
                        }

                    // Goal line (if applicable)
                    if let goal = goalForMetric {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(Color.agonAccent.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Goal")
                                    .font(.caption2)
                                    .foregroundStyle(Color.agonAccent)
                            }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.agonBorder.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let x = value.location.x
                                        if let date: Date = proxy.value(atX: x) {
                                            selectedPoint = closestPoint(to: date)
                                        }
                                    }
                                    .onEnded { _ in
                                    }
                            )
                            .overlay {
                                if let point = selectedPoint,
                                   let xPos = proxy.position(forX: point.date),
                                   let yPos = proxy.position(forY: point.value) {
                                    VStack(spacing: 2) {
                                        Text(formatValue(point.value))
                                            .font(.caption.bold())
                                            .foregroundStyle(Color.agonAccent)
                                        Text(shortDateLabel(point.date))
                                            .font(.system(size: 9))
                                            .foregroundStyle(Color.agonTextSecondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.agonSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    .position(x: xPos, y: yPos - 30)
                                }
                            }
                    }
                }
                .frame(height: 240)
                .opacity(animateChart ? 1 : 0)
                .offset(y: animateChart ? 0 : 20)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: Color.agonSecondary, label: "Average", dashed: true)
                    if goalForMetric != nil {
                        legendItem(color: Color.agonAccent, label: "Goal", dashed: true)
                    }
                    legendItem(color: Color.green, label: "Above avg", dashed: false)
                    legendItem(color: Color.agonTextSecondary, label: "Below avg", dashed: false)
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Line Chart Content

    @ChartContentBuilder
    private var lineChartContent: some ChartContent {
        ForEach(chartData, id: \.date) { point in
            let hasData = datesWithData.contains(Calendar.current.startOfDay(for: point.date)) && point.value > 0

            if hasData {
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, point.value)
                )
                .foregroundStyle(Color.agonAccent)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.agonAccent.opacity(0.2), Color.agonAccent.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Colour-coded points - green above avg, grey below
                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, point.value)
                )
                .foregroundStyle(point.value >= average ? Color.green : Color.agonTextSecondary)
                .symbolSize(selectedPoint?.date == point.date ? 80 : 40)
            } else {
                // Grey dot for days without data
                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, 0)
                )
                .foregroundStyle(Color.agonBorder)
                .symbolSize(24)
            }

            // Min/max annotations
            if point.value == best {
                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, point.value)
                )
                .annotation(position: .top, spacing: 4) {
                    Text("Best")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.agonAccent)
                }
                .foregroundStyle(.clear)
                .symbolSize(0)
            }

            if point.value == worst && chartData.count > 1 {
                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value(metricType.title, point.value)
                )
                .annotation(position: .bottom, spacing: 4) {
                    Text("Low")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .foregroundStyle(.clear)
                .symbolSize(0)
            }
        }
    }

    // MARK: - Bar Chart Content

    @ChartContentBuilder
    private var barChartContent: some ChartContent {
        ForEach(chartData, id: \.date) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value(metricType.title, point.value)
            )
            .foregroundStyle(point.value >= average ? Color.agonAccent : Color.agonTextSecondary.opacity(0.5))
            .cornerRadius(4)
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        Group {
            if currentStreak > 1 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color.agonAccent)
                    Text("\(currentStreak)-day streak above average!")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Spacer()
                }
                .padding()
                .background(Color.agonAccentTint.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(Color.agonTextPrimary)

            HStack(spacing: 0) {
                SummaryItem(label: "Total", value: formattedTotal)
                SummaryItem(label: "Average", value: formattedAverage)
                SummaryItem(label: "Best", value: formattedBest)
                SummaryItem(label: "Low", value: formattedWorst)
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Legend

    private func legendItem(color: Color, label: String, dashed: Bool) -> some View {
        HStack(spacing: 4) {
            if dashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 14, height: 2)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            Text(label)
                .foregroundStyle(Color.agonTextSecondary)
        }
    }

    // MARK: - Chart Data

    private var chartData: [ChartPoint] {
        // Always show full Mon-Sun
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!

        var points: [ChartPoint] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: monday)!
            let matchingSnapshot = snapshots.first { snapshot in
                calendar.isDate(snapshot.date, inSameDayAs: date)
            }
            let value = matchingSnapshot.map { valueForMetric($0) } ?? 0
            points.append(ChartPoint(date: date, value: value))
        }
        return points
    }

    private var datesWithData: Set<Date> {
        let calendar = Calendar.current
        return Set(snapshots.map { calendar.startOfDay(for: $0.date) })
    }

    private func valueForMetric(_ snapshot: DailySnapshot) -> Double {
        switch metricType {
        case .steps: return snapshot.steps
        case .distanceWalked: return snapshot.distanceWalked
        case .distanceRan: return snapshot.distanceRan
        case .totalSleep: return snapshot.totalSleep
        case .timeInDaylight: return snapshot.timeInDaylight
        case .exerciseMinutes: return snapshot.exerciseMinutes
        }
    }

    // MARK: - Computed Values

    private var total: Double {
        chartData.reduce(0) { $0 + $1.value }
    }

    private var average: Double {
        guard !chartData.isEmpty else { return 0 }
        return total / Double(chartData.count)
    }

    private var best: Double {
        chartData.max(by: { $0.value < $1.value })?.value ?? 0
    }

    private var worst: Double {
        chartData.min(by: { $0.value < $1.value })?.value ?? 0
    }

    private var dayOverDayTrend: Double? {
        let sorted = chartData.sorted { $0.date > $1.date }
        guard sorted.count >= 2 else { return nil }
        let today = sorted[0].value
        let yesterday = sorted[1].value
        guard yesterday > 0 else { return nil }
        return ((today - yesterday) / yesterday) * 100
    }

    private var currentStreak: Int {
        let sorted = chartData.sorted { $0.date > $1.date }
        var streak = 0
        for point in sorted {
            if point.value >= average {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var goalForMetric: Double? {
        switch metricType {
        case .steps: return stepsGoal
        case .exerciseMinutes: return exerciseGoal
        case .distanceWalked: return distanceGoal
        case .distanceRan: return distanceRanGoal
        case .totalSleep: return sleepGoal
        case .timeInDaylight: return daylightGoal
        }
    }

    // MARK: - Helpers

    private func closestPoint(to date: Date) -> ChartPoint? {
        chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }

    private func shortDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private var formattedTotal: String { formatValue(total) }
    private var formattedAverage: String { formatValue(average) }
    private var formattedBest: String { formatValue(best) }
    private var formattedWorst: String { formatValue(worst) }

    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return Int(value).formatted(.number)
        case .distanceWalked, .distanceRan:
            return String(format: "%.1f km", value)
        case .totalSleep:
            return String(format: "%.1f hrs", value)
        case .timeInDaylight, .exerciseMinutes:
            return "\(Int(value)) min"
        }
    }
}

// MARK: - Chart Point

struct ChartPoint {
    let date: Date
    let value: Double
}

// MARK: - Summary Item

struct SummaryItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        MetricDetailView(
            metricType: .steps,
            snapshots: [],
            periodTitle: "Last 7 Days"
        )
    }
}
