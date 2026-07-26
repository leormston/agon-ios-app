import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var snapshot: DailySnapshot?
    @Published var isLoading = false
    @Published var isSyncing = false
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?
    @Published var syncMessage: String?
    @Published var syncsRemaining: Int = 10

    private let healthService = HealthKitService.shared
    private let apiService = APIService.shared

    private let maxDailySyncs = 10
    private let syncCountKey = "agon_sync_count"
    private let syncDateKey = "agon_sync_date"

    var metrics: [HealthMetric] {
        snapshot?.metrics ?? []
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
        } else if let error = healthService.authorizationError {
            errorMessage = error
            showPermissionAlert = true
        }

        // Sync profile to backend on every app launch
        await syncProfileToBackend()
    }

    func loadData() async {
        isLoading = true
        snapshot = await healthService.fetchTodaySnapshot()
        isLoading = false
    }

    func refresh() async {
        await loadData()
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
            // New day — reset
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
