import Foundation

// MARK: - Challenges ViewModel

@MainActor
final class ChallengesViewModel: ObservableObject {

    @Published var activeChallenges: [Challenge] = []
    @Published var invitedChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var isCreating = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    // MARK: - Fetch Challenges

    func loadChallenges() async {
        isLoading = true
        errorMessage = nil

        do {
            let rawChallenges = try await apiService.getChallenges()
            let currentUserId = getCurrentUserId()

            var active: [Challenge] = []
            var invited: [Challenge] = []

            for dict in rawChallenges {
                guard let challenge = parseChallenge(from: dict) else { continue }

                if challenge.isActive {
                    if challenge.participants.contains(currentUserId) {
                        active.append(challenge)
                    } else {
                        invited.append(challenge)
                    }
                }
            }

            activeChallenges = active
            invitedChallenges = invited
        } catch {
            errorMessage = "Failed to load challenges"
            print("Challenges error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Create Challenge

    func createChallenge(metric: ChallengeMetric, duration: ChallengeDuration, invitedUserIds: [String]) async -> Bool {
        isCreating = true
        errorMessage = nil

        do {
            _ = try await apiService.createChallenge(
                metric: metric.rawValue,
                duration: duration.rawValue,
                invitedUserIds: invitedUserIds
            )
            await loadChallenges()
            isCreating = false
            return true
        } catch {
            errorMessage = "Failed to create challenge"
            print("Create challenge error: \(error)")
            isCreating = false
            return false
        }
    }

    // MARK: - Join Challenge

    func joinChallenge(_ challenge: Challenge) async {
        errorMessage = nil

        do {
            try await apiService.joinChallenge(challengeId: challenge.id)
            await loadChallenges()
        } catch {
            errorMessage = "Failed to join challenge"
            print("Join challenge error: \(error)")
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await loadChallenges()
    }

    // MARK: - Helpers

    private func getCurrentUserId() -> String {
        return AuthService.shared.currentUser?.id ?? ""
    }

    private func parseChallenge(from dict: [String: Any]) -> Challenge? {
        guard let id = dict["challengeId"] as? String,
              let creatorId = dict["creatorId"] as? String,
              let metric = dict["metric"] as? String,
              let startDate = dict["startDate"] as? String,
              let endDate = dict["endDate"] as? String,
              let status = dict["status"] as? String,
              let createdAt = dict["createdAt"] as? String else {
            return nil
        }

        let participants = dict["participants"] as? [String] ?? []

        return Challenge(
            id: id,
            creatorId: creatorId,
            metric: metric,
            startDate: startDate,
            endDate: endDate,
            status: status,
            participants: participants,
            createdAt: createdAt
        )
    }
}
