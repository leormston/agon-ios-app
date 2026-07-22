import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

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
                                Text("L")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.white)
                            }

                        Text("Louie")
                            .font(.title2.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                        Text("Member since 2024")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
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
