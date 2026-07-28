import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Greeting
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.greeting)
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text(viewModel.periodTitle)
                            .font(.title.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Time Period Tabs
                HStack(spacing: 0) {
                    DashboardTab(title: "Today", isSelected: viewModel.selectedPeriod == .today) {
                        Task { await viewModel.selectPeriod(.today) }
                    }
                    DashboardTab(title: "This Week", isSelected: viewModel.selectedPeriod == .thisWeek) {
                        Task { await viewModel.selectPeriod(.thisWeek) }
                    }
                    DashboardTab(title: "Last 7 Days", isSelected: viewModel.selectedPeriod == .last7Days) {
                        Task { await viewModel.selectPeriod(.last7Days) }
                    }
                }
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)

                // Total / Average toggle (shown for Last 7 Days and This Week)
                if viewModel.selectedPeriod != .today {
                    HStack(spacing: 0) {
                        Button {
                            viewModel.aggregationMode = .total
                        } label: {
                            Text("Total")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.aggregationMode == .total ? Color.agonAccent : Color.clear)
                                .foregroundStyle(viewModel.aggregationMode == .total ? .white : Color.agonTextSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        Button {
                            viewModel.aggregationMode = .average
                        } label: {
                            Text("Average")
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(viewModel.aggregationMode == .average ? Color.agonAccent : Color.clear)
                                .foregroundStyle(viewModel.aggregationMode == .average ? .white : Color.agonTextSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                }

                // Loading / Error / Metric Cards
                if viewModel.isLoading && viewModel.snapshot == nil && viewModel.weekSnapshots.isEmpty {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = viewModel.errorMessage, viewModel.snapshot == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.horizontal)
                } else {
                    // Aggregation label
                    if viewModel.selectedPeriod == .thisWeek || viewModel.selectedPeriod == .last7Days {
                        HStack {
                            Text(viewModel.aggregationMode == .total ? "Totals" : "Daily Average")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // Metric Cards - 2 columns for Today, full-width mini charts for week views
                    if viewModel.selectedPeriod == .today {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(viewModel.metrics) { metric in
                                NavigationLink(destination: MetricDetailView(
                                    metricType: metric.type,
                                    snapshots: viewModel.snapshotsForChart,
                                    periodTitle: viewModel.periodTitle
                                )) {
                                    MetricCard(metric: metric)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.metrics) { metric in
                                NavigationLink(destination: MetricDetailView(
                                    metricType: metric.type,
                                    snapshots: viewModel.snapshotsForChart,
                                    periodTitle: viewModel.periodTitle
                                )) {
                                    MiniChartCard(
                                        metric: metric,
                                        snapshots: viewModel.snapshotsForChart
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Sync Button
                VStack(spacing: 8) {
                    Button {
                        Task { await viewModel.syncNow() }
                    } label: {
                        HStack {
                            if viewModel.isSyncing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.canSync ? Color.agonAccent : Color.agonBorder)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.canSync || viewModel.isSyncing)

                    HStack {
                        if let message = viewModel.syncMessage {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                        Spacer()
                        Text("\(viewModel.syncsRemaining)/10 remaining")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
                .padding(.horizontal)

                // Active Challenge Preview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Challenge")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    VStack(spacing: 8) {
                        Image(systemName: "trophy")
                            .font(.title2)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No active challenges")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Go to Challenges tab to create one")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.agonBackground)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.onAppear()
        }
        .alert("Health Access Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Agon needs access to your health data to show your metrics and power challenges. Please enable it in Settings.")
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let metric: HealthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: metric.type.icon)
                .font(.title2)
                .foregroundStyle(colorForMetric(metric.type))

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.formattedValue)
                        .font(.title3.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text(metric.type.unit)
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Text(metric.type.title)
                    .font(.caption)
                    .foregroundStyle(Color.agonTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForMetric(_ type: HealthMetricType) -> Color {
        switch type {
        case .steps: return Color.agonAccent
        case .distanceWalked: return Color.agonSecondary
        case .distanceRan: return Color.agonAccent
        case .totalSleep: return Color.agonTextSecondary
        case .timeInDaylight: return Color.yellow
        case .exerciseMinutes: return Color.green
        }
    }
}

// MARK: - Circular Progress

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

// MARK: - Mini Chart Card (full-width for week views)

import Charts

struct MiniChartCard: View {
    let metric: HealthMetric
    let snapshots: [DailySnapshot]

    var body: some View {
        HStack(spacing: 12) {
            // Left: icon + value
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: metric.type.icon)
                    .font(.title3)
                    .foregroundStyle(colorForMetric(metric.type))

                Text(metric.formattedValue)
                    .font(.headline.bold())
                    .foregroundStyle(Color.agonTextPrimary)

                Text(metric.type.title)
                    .font(.caption)
                    .foregroundStyle(Color.agonTextSecondary)
            }
            .frame(width: 80, alignment: .leading)

            // Right: mini line chart
            Chart {
                ForEach(chartData, id: \.date) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(colorForMetric(metric.type))
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [colorForMetric(metric.type).opacity(0.2), colorForMetric(metric.type).opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 50)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var chartData: [ChartPoint] {
        snapshots
            .sorted { $0.date < $1.date }
            .map { snapshot in
                ChartPoint(date: snapshot.date, value: valueForMetric(snapshot))
            }
    }

    private func valueForMetric(_ snapshot: DailySnapshot) -> Double {
        switch metric.type {
        case .steps: return snapshot.steps
        case .distanceWalked: return snapshot.distanceWalked
        case .distanceRan: return snapshot.distanceRan
        case .totalSleep: return snapshot.totalSleep
        case .timeInDaylight: return snapshot.timeInDaylight
        case .exerciseMinutes: return snapshot.exerciseMinutes
        }
    }

    private func colorForMetric(_ type: HealthMetricType) -> Color {
        switch type {
        case .steps: return Color.agonAccent
        case .distanceWalked: return Color.agonSecondary
        case .distanceRan: return Color.agonAccent
        case .totalSleep: return Color.agonTextSecondary
        case .timeInDaylight: return Color.yellow
        case .exerciseMinutes: return Color.green
        }
    }
}

// MARK: - Dashboard Tab

struct DashboardTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.agonAccent : Color.clear)
                .foregroundStyle(isSelected ? .white : Color.agonTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    DashboardView()
}
