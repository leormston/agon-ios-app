import Foundation

// MARK: - Challenges ViewModel

@MainActor
final class ChallengesViewModel: ObservableObject {

    @Published var activeChallenges: [Challenge] = []
    @Published var invitedChallenges: [Challenge] = []
    @Published var completedChallenges: [Challenge] = []
    @Published var wonChallenges: [Challenge] = []
    @Published var lostChallenges: [Challenge] = []
    @Published var challengePositions: [String: Int] = [:]
    @Published var friends: [FriendEntry] = []
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
            var completed: [Challenge] = []
            var won: [Challenge] = []
            var lost: [Challenge] = []

            for dict in rawChallenges {
                guard let challenge = parseChallenge(from: dict) else { continue }

                if challenge.isActive {
                    if challenge.participants.contains(currentUserId) {
                        active.append(challenge)
                    } else {
                        invited.append(challenge)
                    }
                } else if challenge.status == "completed" {
                    completed.append(challenge)
                    // Determine if won or lost based on winner field
                    let winner = dict["winner"] as? String
                    if winner == currentUserId {
                        won.append(challenge)
                    } else if challenge.participants.contains(currentUserId) {
                        lost.append(challenge)
                    }
                }
            }

            activeChallenges = active
            invitedChallenges = invited
            completedChallenges = completed
            wonChallenges = won
            lostChallenges = lost
            errorMessage = nil

            // Fetch positions for active challenges in parallel
            await loadPositions(for: active, userId: currentUserId)
        } catch is CancellationError {
            // Ignore - task was cancelled by SwiftUI (e.g. view disappeared)
        } catch let error as NSError where error.code == -999 {
            // Ignore - URLSession request cancelled
        } catch {
            if activeChallenges.isEmpty && invitedChallenges.isEmpty {
                errorMessage = "Failed to load challenges"
            }
            print("Challenges error: \(error)")
        }

        // Load friends separately (non-blocking)
        await loadFriends()

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

    // MARK: - Positions

    private func loadPositions(for challenges: [Challenge], userId: String) async {
        await withTaskGroup(of: (String, Int?).self) { group in
            for challenge in challenges {
                group.addTask {
                    do {
                        guard let data = try await APIService.shared.getChallengeDetails(challengeId: challenge.id) else {
                            return (challenge.id, nil)
                        }
                        if let scores = data["scores"] as? [[String: Any]] {
                            for (index, score) in scores.enumerated() {
                                if (score["userId"] as? String) == userId {
                                    return (challenge.id, index + 1)
                                }
                            }
                        }
                    } catch {}
                    return (challenge.id, nil)
                }
            }

            for await (challengeId, position) in group {
                if let pos = position {
                    challengePositions[challengeId] = pos
                }
            }
        }
    }

    // MARK: - Friends

    private func loadFriends() async {
        do {
            let data = try await apiService.getFriends()
            let accepted = data["accepted"] as? [[String: Any]] ?? []
            friends = accepted.compactMap { dict in
                guard let id = dict["friendId"] as? String else { return nil }
                let name = dict["displayName"] as? String ?? "User"
                return FriendEntry(id: id, name: name)
            }
        } catch {
            print("Failed to load friends: \(error)")
            friends = []
        }
    }
}
