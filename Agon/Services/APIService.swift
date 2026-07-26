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

    // MARK: - Leaderboard

    func getLeaderboard(challengeId: String) async throws -> [String: Any]? {
        let (data, response) = try await request(method: "GET", path: "/leaderboard/\(challengeId)")
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

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .notAuthenticated: return "Not authenticated"
        case .invalidResponse: return "Invalid response from server"
        case .profileUpdateFailed: return "Failed to update profile"
        case .syncFailed: return "Failed to sync health data"
        }
    }
}
