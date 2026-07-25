import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var showError = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and tagline
            VStack(spacing: 16) {
                Image("AgonLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 80)

                Text("Compete. Improve. Together.")
                    .font(.title3)
                    .foregroundStyle(Color.agonTextSecondary)
            }

            Spacer()

            // Sign in buttons
            VStack(spacing: 14) {
                // Apple Sign In
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        authService.signInWithApple(authorization: authorization)
                    case .failure(let error):
                        authService.errorMessage = error.localizedDescription
                        showError = true
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Google Sign In
                Button {
                    Task {
                        await authService.signInWithGoogle()
                        if authService.errorMessage != nil {
                            showError = true
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text("Sign in with Google")
                            .font(.body.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.agonBorder, lineWidth: 1)
                    )
                }
                .disabled(authService.isLoading)

                if authService.isLoading {
                    ProgressView()
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)

            // Terms
            Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                .font(.caption2)
                .foregroundStyle(Color.agonTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 40)

            Spacer()
                .frame(height: 40)
        }
        .background(Color.agonBackground)
        .alert("Sign In Failed", isPresented: $showError) {
            Button("OK") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "Something went wrong. Please try again.")
        }
    }
}

#Preview {
    SignInView()
}
