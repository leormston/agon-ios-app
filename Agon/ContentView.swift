import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                OfflineBanner()

                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tag(0)
                        .tabItem {
                            Label("Dashboard", systemImage: "heart.text.square")
                        }

                    ChallengesView()
                        .tag(1)
                        .tabItem {
                            Label("Challenges", systemImage: "trophy")
                        }

                    CommunityView()
                        .tag(2)
                        .tabItem {
                            Label("Friends", systemImage: "person.2")
                        }
                }
                .tint(Color.agonAccent)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("AgonLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        ProfileAvatarButton()
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Profile Avatar Button

struct ProfileAvatarButton: View {
    @AppStorage("avatarUrl") private var avatarUrl = ""

    var body: some View {
        if !avatarUrl.isEmpty, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                initialCircle
            }
            .frame(width: 30, height: 30)
            .clipShape(Circle())
        } else {
            initialCircle
        }
    }

    private var initialCircle: some View {
        Circle()
            .fill(Color.agonAccent.gradient)
            .frame(width: 30, height: 30)
            .overlay {
                Text(userInitial)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
    }

    private var userInitial: String {
        let name = AuthService.shared.currentUser?.displayName ?? "U"
        return String(name.prefix(1)).uppercased()
    }
}
