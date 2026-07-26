import Foundation

// MARK: - Leaderboard Models

struct LeaderboardEntry: Identifiable {
    let id: String
    let rank: Int
    let displayName: String
    let score: Int
    let isCurrentUser: Bool
}

// MARK: - ViewModel

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func loadLeaderboard(challengeId: String = "daily") async {
        isLoading = true
        errorMessage = nil

        do {
            guard let data = try await apiService.getLeaderboard(challengeId: challengeId) else {
                entries = []
                isLoading = false
                return
            }

            if let participants = data["participants"] as? [[String: Any]] {
                entries = participants.map { p in
                    LeaderboardEntry(
                        id: p["userId"] as? String ?? UUID().uuidString,
                        rank: p["rank"] as? Int ?? 0,
                        displayName: p["displayName"] as? String ?? "Unknown",
                        score: p["score"] as? Int ?? 0,
                        isCurrentUser: p["isCurrentUser"] as? Bool ?? false
                    )
                }
            }
        } catch {
            errorMessage = "Failed to load leaderboard"
            print("Leaderboard error: \(error)")
        }

        isLoading = false
    }

    func refresh(challengeId: String = "daily") async {
        await loadLeaderboard(challengeId: challengeId)
    }
}
