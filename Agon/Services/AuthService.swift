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

        // Open in Safari — the redirect will come back via URL scheme
        await MainActor.run {
            UIApplication.shared.open(url)
        }

        isLoading = false
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
                        // Load stored Cognito tokens
                        CognitoService.shared.loadStoredTokens()
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
            CognitoService.shared.loadStoredTokens()
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
