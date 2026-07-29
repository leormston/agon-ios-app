import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(Color.agonBackground)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

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

                    FeedComingSoonView()
                        .tag(1)
                        .tabItem {
                            Label("Feed", systemImage: "text.bubble")
                        }

                    ChallengesView()
                        .tag(2)
                        .tabItem {
                            Label("Challenges", systemImage: "trophy")
                        }

                    CommunityView()
                        .tag(3)
                        .tabItem {
                            Label("Friends", systemImage: "person.2")
                        }
                }
                .tint(Color.agonAccent)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        selectedTab = 0
                    } label: {
                        Image("AgonLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
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
