import SwiftUI

struct OnboardingView: View {
    @ObservedObject var healthService = HealthKitService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.agonAccent)
                .padding(.bottom, 24)

            // Title
            Text("Connect Your Health Data")
                .font(.title2.bold())
                .foregroundStyle(Color.agonTextPrimary)
                .padding(.bottom, 8)

            // Description
            Text("Agon uses Apple Health to track your progress and power challenges. We'll need your permission to read your health metrics.")
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            // Metrics we'll access
            VStack(alignment: .leading, spacing: 12) {
                PermissionRow(icon: "figure.walk", text: "Steps & Distance")
                PermissionRow(icon: "moon.fill", text: "Sleep Duration")
                PermissionRow(icon: "flame", text: "Calories Burned")
                PermissionRow(icon: "heart.fill", text: "Heart Rate")
                PermissionRow(icon: "figure.run", text: "Exercise Minutes")
            }
            .padding(.horizontal, 40)

            Spacer()

            // Buttons
            VStack(spacing: 12) {
                Button {
                    Task {
                        isRequesting = true
                        await healthService.requestAuthorization()
                        isRequesting = false
                        hasCompletedOnboarding = true
                    }
                } label: {
                    if isRequesting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    } else {
                        Text("Connect Health Data")
                            .font(.body.bold())
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                }
                .background(Color.agonAccent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isRequesting)

                Button {
                    hasCompletedOnboarding = true
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)

            Spacer()
                .frame(height: 40)
        }
        .background(Color.agonBackground)
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.agonAccent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
        }
    }
}

#Preview {
    OnboardingView()
}
