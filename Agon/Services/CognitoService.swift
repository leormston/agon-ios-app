import Foundation

// MARK: - Cognito Configuration

struct CognitoConfig {
    static let userPoolId = "eu-west-2_SqjPkClKx"
    static let clientId = "1p8ijeoldmpe4j068e6g71qimm"
    static let region = "eu-west-2"
    static let domain = "agon-dev"
    static let redirectUri = "agon://callback"

    static var hostedUIBaseURL: String {
        "https://\(domain).auth.\(region).amazoncognito.com"
    }

    static var tokenEndpoint: String {
        "\(hostedUIBaseURL)/oauth2/token"
    }
}

// MARK: - Token Response

struct CognitoTokenResponse: Codable {
    let accessToken: String
    let idToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case idToken = "id_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - Cognito Service

@MainActor
final class CognitoService: ObservableObject {

    static let shared = CognitoService()

    @Published var accessToken: String?
    @Published var idToken: String?

    // MARK: - Exchange Apple Token for Cognito Session

    func exchangeAppleToken(identityToken: String) async throws {
        // Use the Cognito token endpoint with the Apple identity token
        let url = URL(string: CognitoConfig.tokenEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
            "client_id": CognitoConfig.clientId,
            "subject_token": identityToken,
            "subject_token_type": "urn:ietf:params:oauth:token-type:id_token",
            "scope": "openid email profile",
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        guard let response = httpResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw CognitoError.tokenExchangeFailed
        }

        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        idToken = tokenResponse.idToken

        // Store tokens securely
        AuthService.shared.saveToKeychain(key: "cognito_access_token", value: tokenResponse.accessToken)
        AuthService.shared.saveToKeychain(key: "cognito_id_token", value: tokenResponse.idToken)
        if let refresh = tokenResponse.refreshToken {
            AuthService.shared.saveToKeychain(key: "cognito_refresh_token", value: refresh)
        }
    }

    // MARK: - Refresh Token

    func refreshSession() async throws {
        guard let refreshToken = AuthService.shared.getFromKeychain(key: "cognito_refresh_token") else {
            throw CognitoError.noRefreshToken
        }

        let url = URL(string: CognitoConfig.tokenEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "client_id": CognitoConfig.clientId,
            "refresh_token": refreshToken,
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        guard let response = httpResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw CognitoError.refreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        idToken = tokenResponse.idToken

        AuthService.shared.saveToKeychain(key: "cognito_access_token", value: tokenResponse.accessToken)
        AuthService.shared.saveToKeychain(key: "cognito_id_token", value: tokenResponse.idToken)
    }

    // MARK: - Load stored tokens

    func loadStoredTokens() {
        accessToken = AuthService.shared.getFromKeychain(key: "cognito_access_token")
        idToken = AuthService.shared.getFromKeychain(key: "cognito_id_token")
    }

    // MARK: - Clear on sign out

    func clearTokens() {
        accessToken = nil
        idToken = nil
    }
}

// MARK: - Errors

enum CognitoError: LocalizedError {
    case tokenExchangeFailed
    case noRefreshToken
    case refreshFailed

    var errorDescription: String? {
        switch self {
        case .tokenExchangeFailed: return "Failed to exchange token with Cognito"
        case .noRefreshToken: return "No refresh token available"
        case .refreshFailed: return "Failed to refresh session"
        }
    }
}
