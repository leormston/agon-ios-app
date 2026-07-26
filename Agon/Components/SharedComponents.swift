import SwiftUI

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(Color.agonAccent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Error View with Retry

struct ErrorView: View {
    let message: String
    let retryAction: (() async -> Void)?

    init(_ message: String, retryAction: (() async -> Void)? = nil) {
        self.message = message
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(Color.agonAccent)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
                .multilineTextAlignment(.center)

            if let retry = retryAction {
                Button {
                    Task { await retry() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.agonAccent)
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Offline Banner

struct OfflineBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text("You're offline. Some features may not work.")
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.agonTextSecondary)
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.agonTextSecondary)
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(Color.agonTextPrimary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingView()
        ErrorView("Something went wrong") { }
        OfflineBanner()
        EmptyStateView(icon: "trophy", title: "No challenges", subtitle: "Create one to get started")
    }
    .padding()
    .background(Color.agonBackground)
}
