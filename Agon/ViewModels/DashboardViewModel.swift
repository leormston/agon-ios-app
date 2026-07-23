import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var snapshot: DailySnapshot?
    @Published var isLoading = false
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?

    private let healthService = HealthKitService.shared

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
    }

    func loadData() async {
        isLoading = true
        snapshot = await healthService.fetchTodaySnapshot()
        isLoading = false
    }

    func refresh() async {
        await loadData()
    }
}
