import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var snapshot: DailySnapshot?
    @Published var isLoading = false
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?

    private let healthService = HealthKitService.shared
    private let apiService = APIService.shared

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

    // MARK: - Actions

    func onAppear() async {
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

        // Sync health data to backend after fetching
        if let snapshot = snapshot {
            await syncHealthToBackend(snapshot: snapshot)
        }
    }

    func refresh() async {
        await loadData()
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
            // Non-blocking — sync failures shouldn't affect the UI
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
}
