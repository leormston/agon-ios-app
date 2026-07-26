import Foundation
import AuthenticationServices
import Security

// MARK: - Auth Provider

enum AuthProvider: String {
    case apple
    case google
}

// MARK: - User Profile

struct UserProfile: Codable {
    let id: String
    let email: String?
    let displayName: String?
    let provider: String
    let createdAt: Date

    static let storageKey = "agon_user_profile"
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainService = "com.agon.auth"

    private init() {
        loadStoredSession()
    }

    /// Call after AuthService.shared is fully initialized (from AgonApp)
    func restoreCognitoSession() {
        if isAuthenticated {
            CognitoService.shared.loadStoredTokens()
        }
    }

    // MARK: - Public API

    func signInWithApple(authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Failed to get Apple credentials"
            return
        }

        let userId = credential.user
        let email = credential.email
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        // Store the identity token for Cognito exchange
        if let identityToken = credential.identityToken,
           let tokenString = String(data: identityToken, encoding: .utf8) {
            saveToKeychain(key: "apple_id_token", value: tokenString)

            // Exchange Apple token for Cognito session
            Task {
                do {
                    try await CognitoService.shared.exchangeAppleToken(identityToken: tokenString)
                } catch {
                    print("Cognito exchange failed (will work offline): \(error)")
                }

                // Sync profile to backend
                do {
                    try await APIService.shared.updateProfile(
                        displayName: fullName.isEmpty ? nil : fullName,
                        email: email,
                        provider: AuthProvider.apple.rawValue
                    )
                } catch {
                    print("Profile sync failed (will retry later): \(error)")
                }
            }
        }

        let profile = UserProfile(
            id: userId,
            email: email,
            displayName: fullName.isEmpty ? nil : fullName,
            provider: AuthProvider.apple.rawValue,
            createdAt: Date()
        )

        completeSignIn(profile: profile)
    }

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil

        // Google Sign-In via Cognito Hosted UI
        // This opens the Cognito hosted login page with Google as the provider
        guard let url = URL(string: "\(CognitoConfig.hostedUIBaseURL)/oauth2/authorize?response_type=code&client_id=\(CognitoConfig.clientId)&redirect_uri=\(CognitoConfig.redirectUri)&identity_provider=Google&scope=openid+email+profile") else {
            isLoading = false
            errorMessage = "Failed to construct Google sign-in URL"
            return
        }

        // Open in Safari - the redirect will come back via URL scheme
        await MainActor.run {
            UIApplication.shared.open(url)
        }

        isLoading = false
    }

    func handleGoogleCallback(authorizationCode: String) async {
        isLoading = true
        errorMessage = nil

        do {
            // Exchange auth code for Cognito tokens
            let tokens = try await exchangeCodeForTokens(code: authorizationCode)

            // Store tokens
            saveToKeychain(key: "cognito_access_token", value: tokens.accessToken)
            saveToKeychain(key: "cognito_id_token", value: tokens.idToken)
            if let refresh = tokens.refreshToken {
                saveToKeychain(key: "cognito_refresh_token", value: refresh)
            }

            CognitoService.shared.accessToken = tokens.accessToken
            CognitoService.shared.idToken = tokens.idToken

            // Decode user info from ID token
            let userInfo = decodeJWTPayload(tokens.idToken)
            let userId = userInfo["sub"] as? String ?? UUID().uuidString
            let email = userInfo["email"] as? String
            let name = userInfo["name"] as? String

            let profile = UserProfile(
                id: userId,
                email: email,
                displayName: name,
                provider: AuthProvider.google.rawValue,
                createdAt: Date()
            )

            completeSignIn(profile: profile)

            // Sync profile to backend
            try? await APIService.shared.updateProfile(
                displayName: name,
                email: email,
                provider: AuthProvider.google.rawValue
            )
        } catch {
            errorMessage = "Google sign-in failed: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Token Exchange

    private func exchangeCodeForTokens(code: String) async throws -> CognitoTokenResponse {
        let url = URL(string: CognitoConfig.tokenEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "client_id": CognitoConfig.clientId,
            "code": code,
            "redirect_uri": CognitoConfig.redirectUri,
        ]

        request.httpBody = body
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        guard let response = httpResponse as? HTTPURLResponse, response.statusCode == 200 else {
            throw CognitoError.tokenExchangeFailed
        }

        return try JSONDecoder().decode(CognitoTokenResponse.self, from: data)
    }

    // MARK: - JWT Decode Helper

    private func decodeJWTPayload(_ jwt: String) -> [String: Any] {
        let parts = jwt.split(separator: ".")
        guard parts.count == 3 else { return [:] }

        var base64 = String(parts[1])
        // Pad base64 string
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }

        return json
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        removeFromKeychain(key: "apple_id_token")
        removeFromKeychain(key: "google_id_token")
        removeFromKeychain(key: "cognito_access_token")
        removeFromKeychain(key: "cognito_id_token")
        removeFromKeychain(key: "cognito_refresh_token")
        CognitoService.shared.clearTokens()
        UserDefaults.standard.removeObject(forKey: UserProfile.storageKey)
    }

    // MARK: - Session Management

    private func completeSignIn(profile: UserProfile) {
        currentUser = profile
        isAuthenticated = true
        errorMessage = nil
        isLoading = false
        saveProfile(profile)
    }

    private func loadStoredSession() {
        guard let data = UserDefaults.standard.data(forKey: UserProfile.storageKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return
        }

        // Verify Apple credential is still valid
        if profile.provider == AuthProvider.apple.rawValue {
            let provider = ASAuthorizationAppleIDProvider()
            provider.getCredentialState(forUserID: profile.id) { [weak self] state, _ in
                Task { @MainActor in
                    switch state {
                    case .authorized:
                        self?.currentUser = profile
                        self?.isAuthenticated = true
                    case .revoked, .notFound:
                        self?.signOut()
                    default:
                        break
                    }
                }
            }
        } else {
            currentUser = profile
            isAuthenticated = true
        }
    }

    private func saveProfile(_ profile: UserProfile) {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: UserProfile.storageKey)
        }
    }

    // MARK: - Keychain Helpers

    func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func removeFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
