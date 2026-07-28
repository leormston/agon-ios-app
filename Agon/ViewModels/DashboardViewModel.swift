import Foundation
import SwiftUI

// MARK: - Dashboard Period

enum DashboardPeriod {
    case today
    case last7Days
    case thisWeek
}

enum AggregationMode: String {
    case total = "Total"
    case average = "Average"
}

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var snapshot: DailySnapshot?
    @Published var weekSnapshots: [DailySnapshot] = []
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?
    @Published var syncMessage: String?
    @Published var syncsRemaining: Int = 10
    @Published var selectedDate: Date = .now
    @Published var showWeekSummary = false
    @Published var selectedPeriod: DashboardPeriod = .today
    @Published var aggregationMode: AggregationMode = .total

    private let healthService = HealthKitService.shared
    private let apiService = APIService.shared

    private let maxDailySyncs = 10
    private let syncCountKey = "agon_sync_count"
    private let syncDateKey = "agon_sync_date"

    var metrics: [HealthMetric] {
        switch selectedPeriod {
        case .today:
            return snapshot?.metrics ?? []
        case .last7Days, .thisWeek:
            return aggregatedMetrics
        }
    }

    var aggregatedMetrics: [HealthMetric] {
        guard !weekSnapshots.isEmpty else { return [] }
        let count = Double(weekSnapshots.count)
        let totalSteps = weekSnapshots.reduce(0.0) { $0 + $1.steps }
        let totalDistanceWalked = weekSnapshots.reduce(0.0) { $0 + $1.distanceWalked }
        let totalDistanceRan = weekSnapshots.reduce(0.0) { $0 + $1.distanceRan }
        let totalSleep = weekSnapshots.reduce(0.0) { $0 + $1.totalSleep }
        let totalDaylight = weekSnapshots.reduce(0.0) { $0 + $1.timeInDaylight }
        let totalExercise = weekSnapshots.reduce(0.0) { $0 + $1.exerciseMinutes }

        let divisor = aggregationMode == .average ? count : 1.0
        let today = Date.now
        return [
            HealthMetric(type: .steps, value: totalSteps / divisor, date: today),
            HealthMetric(type: .distanceWalked, value: totalDistanceWalked / divisor, date: today),
            HealthMetric(type: .distanceRan, value: totalDistanceRan / divisor, date: today),
            HealthMetric(type: .totalSleep, value: totalSleep / divisor, date: today),
            HealthMetric(type: .timeInDaylight, value: totalDaylight / divisor, date: today),
            HealthMetric(type: .exerciseMinutes, value: totalExercise / divisor, date: today),
        ]
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good morning 👋"
        case 12..<17: return "Good afternoon 👋"
        case 17..<22: return "Good evening 👋"
        default: return "Good night 👋"
        }
    }

    var canSync: Bool {
        syncsRemaining > 0
    }

    var canGoBack: Bool {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: .now))!
        return Calendar.current.startOfDay(for: selectedDate) > sevenDaysAgo
    }

    var canGoForward: Bool {
        Calendar.current.startOfDay(for: selectedDate) < Calendar.current.startOfDay(for: .now)
    }

    var selectedDateLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    var periodTitle: String {
        switch selectedPeriod {
        case .today: return "Your Health Today"
        case .last7Days: return "Last 7 Days"
        case .thisWeek: return "This Week"
        }
    }

    var snapshotsForChart: [DailySnapshot] {
        return weekSnapshots
    }

    func selectPeriod(_ period: DashboardPeriod) async {
        selectedPeriod = period
        aggregationMode = .total
        switch period {
        case .today:
            showWeekSummary = false
            selectedDate = .now
            await loadData()
            // Load week data in background for charts
            if weekSnapshots.isEmpty {
                await loadWeekSnapshotsInBackground()
            }
        case .last7Days:
            showWeekSummary = true
            await loadLast7Days()
        case .thisWeek:
            showWeekSummary = true
            aggregationMode = .average
            await loadThisWeek()
        }
    }

    func toggleAggregation() {
        aggregationMode = aggregationMode == .total ? .average : .total
    }

    private func loadLast7Days() async {
        isLoading = true
        var snapshots: [DailySnapshot] = []
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now)!
            let snap = await healthService.fetchSnapshot(for: date)
            snapshots.append(snap)
        }
        weekSnapshots = snapshots
        isLoading = false
    }

    private func loadWeekSnapshotsInBackground() async {
        var snapshots: [DailySnapshot] = []
        for dayOffset in 0..<30 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now)!
            let snap = await healthService.fetchSnapshot(for: date)
            snapshots.append(snap)
        }
        weekSnapshots = snapshots
    }

    private func loadThisWeek() async {
        isLoading = true
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        // Monday = 2 in gregorian. Days since Monday:
        let daysSinceMonday = (weekday + 5) % 7
        var snapshots: [DailySnapshot] = []
        for dayOffset in 0...daysSinceMonday {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let snap = await healthService.fetchSnapshot(for: date)
            snapshots.append(snap)
        }
        weekSnapshots = snapshots
        isLoading = false
    }

    // MARK: - Actions

    func onAppear() async {
        loadSyncCount()

        guard healthService.isHealthKitAvailable else {
            errorMessage = "HealthKit is not available on this device."
            return
        }

        await healthService.requestAuthorization()

        if healthService.isAuthorized {
            await loadData()
            await loadWeekSnapshotsInBackground()
            await syncPast30Days()
        } else if let error = healthService.authorizationError {
            errorMessage = error
            showPermissionAlert = true
        }

        // Sync profile to backend on every app launch
        await syncProfileToBackend()
    }

    func loadData() async {
        isLoading = true
        snapshot = await healthService.fetchSnapshot(for: selectedDate)
        isLoading = false
    }

    func fetchSnapshot(for date: Date) async {
        isLoading = true
        selectedDate = date
        snapshot = await healthService.fetchSnapshot(for: date)
        isLoading = false
    }

    func goBack() async {
        guard canGoBack else { return }
        let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        await fetchSnapshot(for: newDate)
    }

    func goForward() async {
        guard canGoForward else { return }
        let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        await fetchSnapshot(for: newDate)
    }

    func toggleWeekSummary() async {
        showWeekSummary.toggle()
        if showWeekSummary && weekSnapshots.isEmpty {
            await loadWeekSnapshots()
        }
    }

    func refresh() async {
        if showWeekSummary {
            await loadWeekSnapshots()
        } else {
            await loadData()
        }
    }

    /// Manual sync triggered by the user (limited to 10/day)
    func syncNow() async {
        guard canSync else {
            syncMessage = "You've used all 10 syncs for today. Resets at midnight."
            return
        }

        isSyncing = true
        syncMessage = nil

        // Refresh health data first
        await loadData()

        // Sync to backend
        if let snapshot = snapshot {
            await syncHealthToBackend(snapshot: snapshot)
            incrementSyncCount()
            syncMessage = "Synced! \(syncsRemaining) syncs remaining today."
        } else {
            syncMessage = "No health data to sync."
        }

        isSyncing = false

        // Clear message after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            syncMessage = nil
        }
    }

    // MARK: - 7-Day Sync

    private let past30DaysSyncKey = "agon_past30_sync_date"

    func syncPast30Days() async {
        // Only run once per day
        let today = Calendar.current.startOfDay(for: .now)
        let lastSync = UserDefaults.standard.object(forKey: past30DaysSyncKey) as? Date ?? .distantPast
        let lastSyncDay = Calendar.current.startOfDay(for: lastSync)
        guard lastSyncDay < today else { return }

        var days: [[String: Any]] = []
        let calendar = Calendar.current

        for offset in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let snap = await healthService.fetchSnapshot(for: date)

            let dateFormatter = ISO8601DateFormatter()
            let dateString = String(dateFormatter.string(from: date).prefix(10))

            let metrics: [String: Any] = [
                "steps": snap.steps,
                "distanceWalked": snap.distanceWalked,
                "distanceRan": snap.distanceRan,
                "totalSleep": snap.totalSleep,
                "timeInDaylight": snap.timeInDaylight,
                "exerciseMinutes": snap.exerciseMinutes,
            ]

            days.append(["date": dateString, "metrics": metrics])
        }

        do {
            try await apiService.syncMultipleDays(days: days)
            UserDefaults.standard.set(Date(), forKey: past30DaysSyncKey)
            print("Past 30 days synced to backend")
        } catch {
            print("Past 30 days sync failed: \(error)")
        }
    }

    // MARK: - Week Snapshots

    private func loadWeekSnapshots() async {
        isLoading = true
        var snapshots: [DailySnapshot] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for offset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let snap = await healthService.fetchSnapshot(for: date)
            snapshots.append(snap)
        }

        weekSnapshots = snapshots
        isLoading = false
    }

    // MARK: - Backend Sync

    private func syncHealthToBackend(snapshot: DailySnapshot) async {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10)

        let metrics: [String: Any] = [
            "steps": snapshot.steps,
            "distanceWalked": snapshot.distanceWalked,
            "distanceRan": snapshot.distanceRan,
            "totalSleep": snapshot.totalSleep,
            "timeInDaylight": snapshot.timeInDaylight,
            "exerciseMinutes": snapshot.exerciseMinutes,
        ]

        do {
            try await apiService.syncHealthData(metrics: metrics, date: String(today))
            print("Health data synced to backend")
        } catch {
            print("Health sync failed (will retry on next open): \(error)")
        }
    }

    private func syncProfileToBackend() async {
        guard let user = AuthService.shared.currentUser else { return }

        do {
            try await apiService.updateProfile(
                displayName: user.displayName,
                email: user.email,
                provider: user.provider
            )
            print("Profile synced to backend")
        } catch {
            print("Profile sync failed (will retry on next open): \(error)")
        }
    }

    // MARK: - Sync Count Management

    private func loadSyncCount() {
        let today = Calendar.current.startOfDay(for: Date())
        let storedDate = UserDefaults.standard.object(forKey: syncDateKey) as? Date ?? .distantPast
        let storedDateStart = Calendar.current.startOfDay(for: storedDate)

        if storedDateStart == today {
            let used = UserDefaults.standard.integer(forKey: syncCountKey)
            syncsRemaining = max(0, maxDailySyncs - used)
        } else {
            // New day - reset
            UserDefaults.standard.set(0, forKey: syncCountKey)
            UserDefaults.standard.set(today, forKey: syncDateKey)
            syncsRemaining = maxDailySyncs
        }
    }

    private func incrementSyncCount() {
        let current = UserDefaults.standard.integer(forKey: syncCountKey)
        UserDefaults.standard.set(current + 1, forKey: syncCountKey)
        syncsRemaining = max(0, maxDailySyncs - (current + 1))
    }
}
