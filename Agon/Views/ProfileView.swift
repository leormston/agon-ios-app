import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService = AuthService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar and Name
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.agonAccent.gradient)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Text(userInitial)
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                            }

                        Text(displayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                        
                        if let email = authService.currentUser?.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                    }
                    .padding(.top)

                    // Stats
                    HStack(spacing: 0) {
                        StatItem(value: "42", label: "Day Streak")
                        StatItem(value: "12", label: "Challenges")
                        StatItem(value: "3", label: "Wins")
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Settings Sections
                    VStack(spacing: 0) {
                        ProfileRow(icon: "heart.fill", title: "Connected Apps", color: Color.agonAccent)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "bell.fill", title: "Notifications", color: Color.agonSecondary)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "target", title: "Goals", color: Color.agonAccent)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "lock.fill", title: "Privacy", color: Color.agonSecondary)
                        Divider().foregroundStyle(Color.agonBorder)
                        ProfileRow(icon: "questionmark.circle.fill", title: "Help & Support", color: Color.agonTextSecondary)
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Feedback
                    VStack(spacing: 0) {
                        Button {
                            openFeedback(type: "bug")
                        } label: {
                            HStack {
                                Image(systemName: "ladybug.fill")
                                    .foregroundStyle(.red)
                                    .frame(width: 28)
                                Text("Report a Bug")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.agonTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                            .padding()
                        }

                        Divider().foregroundStyle(Color.agonBorder)

                        Button {
                            openFeedback(type: "feature")
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                    .frame(width: 28)
                                Text("Feature Request")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.agonTextPrimary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                            .padding()
                        }
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Sign Out
                    Button {
                        authService.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color.agonBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.agonAccent)
                }
            }
        }
    }

    private var userInitial: String {
        let name = authService.currentUser?.displayName ?? "U"
        return String(name.prefix(1)).uppercased()
    }

    private var displayName: String {
        authService.currentUser?.displayName ?? "User"
    }

    private func openFeedback(type: String) {
        let subject = type == "bug" ? "Bug Report — Agon Health" : "Feature Request — Agon Health"
        let body = type == "bug"
            ? "Please describe the bug:\n\n\nSteps to reproduce:\n1.\n2.\n3.\n\nExpected behaviour:\n\nActual behaviour:\n"
            : "Please describe the feature you'd like:\n\n\nWhy would this be useful?\n\n"

        let email = "louie@louie.cloud"
        let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)"
            .addingPercentEncoding(withAllowedCharacters: .urlString) ?? ""

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color.agonAccent)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
