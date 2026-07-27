import SwiftUI
import Charts

struct MetricDetailView: View {
    let metricType: HealthMetricType
    let snapshots: [DailySnapshot]
    let periodTitle: String

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Breakdown")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    if chartData.isEmpty {
                        Text("No data available")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        Chart {
                            ForEach(chartData, id: \.date) { point in
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
                                        colors: [Color.agonAccent.opacity(0.3), Color.agonAccent.opacity(0.0)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                                PointMark(
                                    x: .value("Day", point.date, unit: .day),
                                    y: .value(metricType.title, point.value)
                                )
                                .foregroundStyle(Color.agonAccent)
                                .symbolSize(30)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.agonBorder)
                                AxisValueLabel()
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                        }
                        .frame(height: 220)
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Summary Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary")
                        .font(.headline)
                        .foregroundStyle(Color.agonTextPrimary)

                    HStack(spacing: 0) {
                        SummaryItem(label: "Total", value: formattedTotal)
                        SummaryItem(label: "Average", value: formattedAverage)
                        SummaryItem(label: "Best", value: formattedBest)
                    }
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle(metricType.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Chart Data

    private var chartData: [ChartPoint] {
        snapshots
            .sorted { $0.date < $1.date }
            .map { snapshot in
                ChartPoint(date: snapshot.date, value: valueForMetric(snapshot))
            }
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

    // MARK: - Summary

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

    private var formattedTotal: String {
        formatValue(total)
    }

    private var formattedAverage: String {
        formatValue(average)
    }

    private var formattedBest: String {
        formatValue(best)
    }

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
