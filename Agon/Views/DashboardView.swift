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
                        Text("Your Health Today")
                            .font(.title.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Loading / Error / Metric Cards
                if viewModel.isLoading && viewModel.snapshot == nil {
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
                    // Metric Cards - 2 columns, 3 rows for 6 metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.metrics) { metric in
                            MetricCard(metric: metric)
                        }
                    }
                    .padding(.horizontal)
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

    // MARK: - Helpers

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

#Preview {
    DashboardView()
}
