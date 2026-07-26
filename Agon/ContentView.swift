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
                        .scaledToFit()
                        .frame(height: 28)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
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
