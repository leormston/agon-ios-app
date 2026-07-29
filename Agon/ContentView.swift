import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false

    init() {
        // Hide the default tab bar completely
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                OfflineBanner()

                ZStack(alignment: .bottom) {
                    // Content
                    TabView(selection: $selectedTab) {
                        DashboardView()
                            .tag(0)

                        FeedComingSoonView()
                            .tag(1)

                        ChallengesView()
                            .tag(2)

                        CommunityView()
                            .tag(3)
                    }

                    // Custom tab bar
                    CustomTabBar(selectedTab: $selectedTab)
                }
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

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(icon: String, label: String)] = [
        ("heart.text.square", "Dashboard"),
        ("text.bubble", "Feed"),
        ("trophy", "Challenges"),
        ("person.2", "Friends"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 20))
                        Text(tabs[index].label)
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(selectedTab == index ? Color.agonAccent : Color.agonTextSecondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.agonBackground.opacity(0.85)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
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
