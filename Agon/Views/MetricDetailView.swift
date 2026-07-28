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
    @State private var weekOffset: Int = 0
    @State private var allSnapshots: [DailySnapshot] = []
    @State private var isLoadingWeeks = false

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
        .task {
            await loadAllSnapshots()
        }
    }

    private func loadAllSnapshots() async {
        isLoadingWeeks = true
        let healthService = HealthKitService.shared
        let calendar = Calendar.current

        // Load from HealthKit (local device data)
        var healthKitSnapshots: [DailySnapshot] = []
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: .now)!
            let snap = await healthService.fetchSnapshot(for: date)
            healthKitSnapshots.append(snap)
        }

        // Load from backend (data from any source - Strava, Garmin, etc)
        var backendSnapshots: [DailySnapshot] = []
        if let rawSnapshots = try? await APIService.shared.getMySnapshots(days: 30) {
            for raw in rawSnapshots {
                if let dateStr = raw["date"] as? String,
                   let metrics = raw["metrics"] as? [String: Any] {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let date = formatter.date(from: dateStr) {
                        let snap = DailySnapshot(
                            date: date,
                            steps: (metrics["steps"] as? Double) ?? 0,
                            distanceWalked: (metrics["distanceWalked"] as? Double) ?? 0,
                            distanceRan: (metrics["distanceRan"] as? Double) ?? 0,
                            totalSleep: (metrics["totalSleep"] as? Double) ?? 0,
                            timeInDaylight: (metrics["timeInDaylight"] as? Double) ?? 0,
                            exerciseMinutes: (metrics["exerciseMinutes"] as? Double) ?? 0
                        )
                        backendSnapshots.append(snap)
                    }
                }
            }
        }

        // Merge: prefer HealthKit data for days that have it, use backend for others
        var merged: [Date: DailySnapshot] = [:]
        for snap in backendSnapshots {
            merged[calendar.startOfDay(for: snap.date)] = snap
        }
        for snap in healthKitSnapshots {
            let day = calendar.startOfDay(for: snap.date)
            // HealthKit overwrites backend if it has non-zero data
            if snap.steps > 0 || snap.exerciseMinutes > 0 || snap.distanceWalked > 0 {
                merged[day] = snap
            }
        }

        allSnapshots = Array(merged.values)
        isLoadingWeeks = false
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
            Text(weekLabel)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)

            // Week-over-week comparison
            if let comparison = weekOverWeekChange {
                HStack(spacing: 4) {
                    Image(systemName: comparison >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text(String(format: "%+.1f%% vs previous week", comparison))
                        .font(.caption.bold())
                }
                .foregroundStyle(comparison >= 0 ? Color.agonAccent : Color.agonTextSecondary)
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
            // Week navigation
            HStack {
                Button {
                    withAnimation {
                        weekOffset -= 1
                        selectedPoint = nil
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(canGoBackWeek ? Color.agonAccent : Color.agonBorder)
                }
                .disabled(!canGoBackWeek)

                Spacer()

                Text(weekLabel)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.agonTextPrimary)

                Spacer()

                Button {
                    withAnimation {
                        weekOffset += 1
                        selectedPoint = nil
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(canGoForwardWeek ? Color.agonAccent : Color.agonBorder)
                }
                .disabled(!canGoForwardWeek)
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

                    // Goal line (if applicable)
                    if let goal = goalForMetric {
                        RuleMark(y: .value("Goal", goal))
                            .foregroundStyle(Color.agonAccent.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
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

            // Min/max annotations (only on real data points)
            if hasData && point.value == best && dataPoints.count > 1 {
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

            if hasData && point.value == worst && dataPoints.count > 1 {
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
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        let targetMonday = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentMonday)!

        let dataSource = allSnapshots.isEmpty ? snapshots : allSnapshots

        var points: [ChartPoint] = []
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: targetMonday)!
            let matchingSnapshot = dataSource.first { snapshot in
                calendar.isDate(snapshot.date, inSameDayAs: date)
            }
            let value = matchingSnapshot.map { valueForMetric($0) } ?? 0
            points.append(ChartPoint(date: date, value: value))
        }
        return points
    }

    private var datesWithData: Set<Date> {
        let calendar = Calendar.current
        let dataSource = allSnapshots.isEmpty ? snapshots : allSnapshots
        return Set(dataSource.map { calendar.startOfDay(for: $0.date) })
    }

    private var canGoBackWeek: Bool {
        weekOffset > -3 // Up to 4 weeks back (30 days of data)
    }

    private var canGoForwardWeek: Bool {
        weekOffset < 0
    }

    private var weekLabel: String {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!
        let targetMonday = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentMonday)!
        let targetSunday = calendar.date(byAdding: .day, value: 6, to: targetMonday)!

        if weekOffset == 0 { return "This Week" }
        if weekOffset == -1 { return "Last Week" }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: targetMonday)) - \(formatter.string(from: targetSunday))"
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

    // Only points that have real data (not grey placeholder dots)
    private var dataPoints: [ChartPoint] {
        chartData.filter { point in
            datesWithData.contains(Calendar.current.startOfDay(for: point.date)) && point.value > 0
        }
    }

    private var total: Double {
        dataPoints.reduce(0) { $0 + $1.value }
    }

    private var average: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return total / Double(dataPoints.count)
    }

    private var best: Double {
        dataPoints.max(by: { $0.value < $1.value })?.value ?? 0
    }

    private var worst: Double {
        dataPoints.min(by: { $0.value < $1.value })?.value ?? 0
    }

    private var weekOverWeekChange: Double? {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today)!

        // Current selected week
        let targetMonday = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentMonday)!
        // Previous week
        let prevMonday = calendar.date(byAdding: .weekOfYear, value: weekOffset - 1, to: currentMonday)!

        let dataSource = allSnapshots.isEmpty ? snapshots : allSnapshots

        let thisWeekAvg = averageForWeek(startingMonday: targetMonday, dataSource: dataSource)
        let prevWeekAvg = averageForWeek(startingMonday: prevMonday, dataSource: dataSource)

        guard prevWeekAvg > 0 else { return nil }
        return ((thisWeekAvg - prevWeekAvg) / prevWeekAvg) * 100
    }

    private func averageForWeek(startingMonday: Date, dataSource: [DailySnapshot]) -> Double {
        let calendar = Calendar.current
        var total: Double = 0
        var daysWithData: Int = 0
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: i, to: startingMonday)!
            if let snap = dataSource.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
                let value = valueForMetric(snap)
                if value > 0 {
                    total += value
                    daysWithData += 1
                }
            }
        }
        guard daysWithData > 0 else { return 0 }
        return total / Double(daysWithData)
    }

    private var currentStreak: Int {
        let sorted = dataPoints.sorted { $0.date > $1.date }
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
