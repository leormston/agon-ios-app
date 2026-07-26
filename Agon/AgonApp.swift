import SwiftUI

@main
struct AgonApp: App {
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !authService.isAuthenticated {
                    SignInView()
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                } else {
                    ContentView()
                }
            }
            .animation(.easeInOut, value: authService.isAuthenticated)
            .animation(.easeInOut, value: hasCompletedOnboarding)
            .onOpenURL { url in
                handleCallback(url: url)
            }
            .task {
                authService.restoreCognitoSession()
            }
        }
    }

    private func handleCallback(url: URL) {
        // Handle agon://callback?code=XXXX from Cognito Hosted UI
        guard url.scheme == "agon",
              url.host == "callback",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            return
        }

        Task {
            await authService.handleGoogleCallback(authorizationCode: code)
        }
    }
}
