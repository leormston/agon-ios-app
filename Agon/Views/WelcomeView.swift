import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @State private var currentPage = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            icon: "heart.text.square.fill",
            title: "Track Your Health",
            description: "Monitor steps, sleep, exercise and more - all in one place. Syncs automatically with Apple Health.",
            color: .agonAccent
        ),
        WelcomePage(
            icon: "trophy.fill",
            title: "Compete With Friends",
            description: "Create challenges, set goals, and see who can make the most progress. Health is better together.",
            color: .agonSecondary
        ),
        WelcomePage(
            icon: "chart.line.uptrend.xyaxis",
            title: "See Your Progress",
            description: "Track your improvements over time with personalised insights and milestone celebrations.",
            color: .agonAccent
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    WelcomePageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Bottom section
            VStack(spacing: 20) {
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.agonAccent : Color.agonBorder)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenWelcome = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.agonAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Skip
                if currentPage < pages.count - 1 {
                    Button {
                        hasSeenWelcome = true
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.agonBackground)
    }
}

// MARK: - Welcome Page Model

struct WelcomePage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Welcome Page View

struct WelcomePageView: View {
    let page: WelcomePage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 70))
                .foregroundStyle(page.color)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundStyle(Color.agonTextPrimary)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(Color.agonTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
}
