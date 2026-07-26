import Foundation

// MARK: - API Configuration

struct APIConfig {
    static let baseURL = "https://dby9d5g95b.execute-api.eu-west-2.amazonaws.com"
}

// MARK: - API Service

@MainActor
final class APIService: ObservableObject {

    static let shared = APIService()

    private let cognitoService = CognitoService.shared

    // MARK: - Health Check

    func healthCheck() async throws -> Bool {
        let (_, response) = try await request(method: "GET", path: "/health", authenticated: false)
        return response.statusCode == 200
    }

    // MARK: - Profile

    func getProfile() async throws -> [String: Any]? {
        let (data, response) = try await request(method: "GET", path: "/profile")
        guard response.statusCode == 200 else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func updateProfile(displayName: String?, email: String?, provider: String) async throws {
        var body: [String: Any] = ["provider": provider]
        if let name = displayName { body["displayName"] = name }
        if let email = email { body["email"] = email }
        body["createdAt"] = ISO8601DateFormatter().string(from: Date())

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await request(method: "PUT", path: "/profile", body: jsonData)

        guard response.statusCode == 200 else {
            throw APIError.profileUpdateFailed
        }
    }

    // MARK: - Health Sync

    func syncHealthData(metrics: [String: Any], date: String? = nil) async throws {
        var body: [String: Any] = ["metrics": metrics]
        if let date = date {
            body["date"] = date
        }

        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await request(method: "POST", path: "/health/sync", body: jsonData)

        guard response.statusCode == 200 else {
            throw APIError.syncFailed
        }
    }

    // MARK: - Users

    func getAllUsers() async throws -> [[String: Any]] {
        let (data, response) = try await request(method: "GET", path: "/users")
        guard response.statusCode == 200 else { return [] }
        let json = try JSONSerialization.jsonObject(with: data)
        return (json as? [[String: Any]]) ?? ((json as? [String: Any])?["users"] as? [[String: Any]] ?? [])
    }

    // MARK: - Friends

    func sendFriendRequest(friendId: String) async throws {
        let body = try JSONSerialization.data(withJSONObject: ["friendId": friendId])
        let (_, response) = try await request(method: "POST", path: "/friends/request", body: body)
        guard response.statusCode == 200 else {
            throw APIError.friendRequestFailed
        }
    }

    func getFriends() async throws -> [String: Any] {
        let (data, response) = try await request(method: "GET", path: "/friends")
        guard response.statusCode == 200 else { return [:] }
        return (try JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    func acceptFriendRequest(friendId: String) async throws {
        let (_, response) = try await request(method: "POST", path: "/friends/\(friendId)/accept")
        guard response.statusCode == 200 else {
            throw APIError.friendRequestFailed
        }
    }

    func rejectFriendRequest(friendId: String) async throws {
        let (_, response) = try await request(method: "POST", path: "/friends/\(friendId)/reject")
        guard response.statusCode == 200 else {
            throw APIError.friendRequestFailed
        }
    }

    func removeFriend(friendId: String) async throws {
        let (_, response) = try await request(method: "DELETE", path: "/friends/\(friendId)")
        guard response.statusCode == 200 else {
            throw APIError.friendRequestFailed
        }
    }

    // MARK: - Activity Feed

    func getActivityFeed() async throws -> [[String: Any]] {
        let (data, response) = try await request(method: "GET", path: "/activity")
        guard response.statusCode == 200 else { return [] }
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["activity"] as? [[String: Any]] ?? []
    }

    // MARK: - Leaderboard

    func getLeaderboard(challengeId: String) async throws -> [String: Any]? {
        let (data, response) = try await request(method: "GET", path: "/leaderboard/\(challengeId)")
        guard response.statusCode == 200 else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: - Challenges

    func createChallenge(metric: String, duration: String, invitedUserIds: [String]) async throws -> [String: Any]? {
        let body: [String: Any] = [
            "metric": metric,
            "duration": duration,
            "invitedUserIds": invitedUserIds,
        ]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await request(method: "POST", path: "/challenges", body: jsonData)

        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw APIError.challengeCreationFailed
        }

        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    func getChallenges() async throws -> [[String: Any]] {
        let (data, response) = try await request(method: "GET", path: "/challenges")
        guard response.statusCode == 200 else { return [] }
        let json = try JSONSerialization.jsonObject(with: data)
        if let array = json as? [[String: Any]] {
            return array
        }
        if let dict = json as? [String: Any], let challenges = dict["challenges"] as? [[String: Any]] {
            return challenges
        }
        return []
    }

    func joinChallenge(challengeId: String) async throws {
        let (_, response) = try await request(method: "POST", path: "/challenges/\(challengeId)/join")

        guard response.statusCode == 200 else {
            throw APIError.challengeJoinFailed
        }
    }

    func getChallengeDetails(challengeId: String) async throws -> [String: Any]? {
        let (data, response) = try await request(method: "GET", path: "/challenges/\(challengeId)")
        guard response.statusCode == 200 else { return nil }
        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
    }

    // MARK: - Networking

    private func request(
        method: String,
        path: String,
        body: Data? = nil,
        authenticated: Bool = true
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            // Use Cognito token if available, otherwise fall back to Apple identity token
            let token = cognitoService.idToken ?? AuthService.shared.getFromKeychain(key: "apple_id_token")
            guard let bearerToken = token else {
                throw APIError.notAuthenticated
            }
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // If 401, try refreshing the token and retry once
        if httpResponse.statusCode == 401 && authenticated {
            try? await cognitoService.refreshSession()
            let retryToken = cognitoService.idToken ?? AuthService.shared.getFromKeychain(key: "apple_id_token")
            request.setValue("Bearer \(retryToken ?? "")", forHTTPHeaderField: "Authorization")
            let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
            guard let retryHttp = retryResponse as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            return (retryData, retryHttp)
        }

        return (data, httpResponse)
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case invalidResponse
    case profileUpdateFailed
    case syncFailed
    case challengeCreationFailed
    case challengeJoinFailed
    case friendRequestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .notAuthenticated: return "Not authenticated"
        case .invalidResponse: return "Invalid response from server"
        case .profileUpdateFailed: return "Failed to update profile"
        case .syncFailed: return "Failed to sync health data"
        case .challengeCreationFailed: return "Failed to create challenge"
        case .challengeJoinFailed: return "Failed to join challenge"
        case .friendRequestFailed: return "Friend request failed"
        }
    }
}
