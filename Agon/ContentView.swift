import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showProfile = false

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Full screen content
                Group {
                    switch selectedTab {
                    case 0: DashboardView()
                    case 1: FeedComingSoonView()
                    case 2: ChallengesView()
                    case 3: CommunityView()
                    default: DashboardView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating tab bar overlaid on top
                HStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { index in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tabIcon(index))
                                    .font(.system(size: 18))
                                Text(tabLabel(index))
                                    .font(.system(size: 9))
                            }
                            .foregroundStyle(selectedTab == index ? Color.agonAccent : Color.agonTextSecondary)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
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

    private func tabIcon(_ index: Int) -> String {
        switch index {
        case 0: return "heart.text.square"
        case 1: return "text.bubble"
        case 2: return "trophy"
        case 3: return "person.2"
        default: return ""
        }
    }

    private func tabLabel(_ index: Int) -> String {
        switch index {
        case 0: return "Dashboard"
        case 1: return "Feed"
        case 2: return "Challenges"
        case 3: return "Friends"
        default: return ""
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
