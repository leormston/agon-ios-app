import SwiftUI

struct ChallengesView: View {
    @StateObject private var viewModel = ChallengesViewModel()
    @State private var showCreateChallenge = false
    @State private var selectedCategory: ChallengeCategory = .active
    @State private var joinedWeeklyChallenges: [PublicChallenge] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top buttons - Create and Join
                HStack(spacing: 10) {
                    Button {
                        showCreateChallenge = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.agonAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    NavigationLink {
                        PublicChallengesView()
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                            Text("Join")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.agonSurface)
                        .foregroundStyle(Color.agonTextPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.agonBorder, lineWidth: 1)
                        )
                    }
                }

                // Active limit info
                if viewModel.activeChallenges.count >= 7 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption)
                        Text("Max 7 active challenges reached")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.agonTextSecondary)
                }

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChallengeCategory.allCases, id: \.self) { category in
                            Button {
                                withAnimation { selectedCategory = category }
                            } label: {
                                Text(category.title)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.agonAccent : Color.agonSurface)
                                    .foregroundStyle(selectedCategory == category ? .white : Color.agonTextSecondary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Content based on category
                switch selectedCategory {
                case .active:
                    activeSection

                    // Agon Weekly joined challenges underneath
                    agonWeeklySection
                case .completed:
                    completedSection
                case .won:
                    wonSection
                case .lost:
                    lostSection
                }

                // Invited Challenges
                if selectedCategory == .active && !viewModel.invitedChallenges.isEmpty {
                    SectionHeader(title: "Join a Challenge", icon: "plus.circle.fill")

                    ForEach(viewModel.invitedChallenges) { challenge in
                        InvitedChallengeCard(challenge: challenge) {
                            Task {
                                await viewModel.joinChallenge(challenge)
                            }
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadChallenges()
            await loadWeeklyChallenges()
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView(viewModel: viewModel)
        }
    }

    // MARK: - Active Section

    private var activeSection: some View {
        Group {
            SectionHeader(title: "Active Challenges", icon: "flame.fill")

            if viewModel.isLoading && viewModel.activeChallenges.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if viewModel.activeChallenges.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    message: "No active challenges yet",
                    subtitle: "Create one to get started!"
                )
            } else {
                ForEach(viewModel.activeChallenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        ActiveChallengeCard(challenge: challenge, position: viewModel.challengePositions[challenge.id])
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Agon Weekly Section

    private var agonWeeklySection: some View {
        Group {
            SectionHeader(title: "Agon Weekly", icon: "globe")

            // Show joined weekly challenges
            if !joinedWeeklyChallenges.isEmpty {
                ForEach(joinedWeeklyChallenges) { challenge in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(challenge.name)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.agonTextPrimary)
                            HStack(spacing: 8) {
                                Text("Avg: \(formatWeeklyProgress(challenge.progress, unit: challenge.metricUnit))")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonAccent)
                                Text("Bronze: \(formatWeeklyProgress(challenge.bronzeTarget, unit: challenge.metricUnit))")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                        }
                        Spacer()
                        ProgressView(value: min(1.0, challenge.progress / challenge.goldTarget))
                            .tint(challenge.progress >= challenge.bronzeTarget ? Color.agonAccent : Color.agonBorder)
                            .frame(width: 60)
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            NavigationLink(destination: PublicChallengesView()) {
                HStack {
                    Text(joinedWeeklyChallenges.isEmpty ? "Join weekly challenges" : "View all weekly challenges")
                        .font(.caption)
                        .foregroundStyle(Color.agonAccent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .padding()
                .background(Color.agonSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Weekly Helpers

    private func loadWeeklyChallenges() async {
        do {
            let raw = try await APIService.shared.getPublicChallenges()

            let categoryMap: [String: String] = [
                "steps": "walking", "distanceWalked": "distance",
                "totalSleep": "sleep", "distanceRan": "running", "timeInDaylight": "sun"
            ]
            let nameMap: [String: String] = [
                "steps": "Walker", "distanceWalked": "Hiker",
                "totalSleep": "Sleeper", "distanceRan": "Runner", "timeInDaylight": "Sun Seeker"
            ]

            var grouped: [String: (bronze: [String: Any]?, silver: [String: Any]?, gold: [String: Any]?)] = [:]
            for dict in raw {
                guard let metric = dict["metric"] as? String, let tier = dict["tier"] as? String else { continue }
                if grouped[metric] == nil { grouped[metric] = (nil, nil, nil) }
                switch tier {
                case "bronze": grouped[metric]?.bronze = dict
                case "silver": grouped[metric]?.silver = dict
                case "gold": grouped[metric]?.gold = dict
                default: break
                }
            }

            joinedWeeklyChallenges = grouped.compactMap { metric, tiers -> PublicChallenge? in
                let joined = (tiers.bronze?["joined"] as? Bool) ?? false
                guard joined else { return nil }

                let bronzeTarget = (tiers.bronze?["target"] as? Double) ?? Double((tiers.bronze?["target"] as? Int) ?? 0)
                let silverTarget = (tiers.silver?["target"] as? Double) ?? Double((tiers.silver?["target"] as? Int) ?? 0)
                let goldTarget = (tiers.gold?["target"] as? Double) ?? Double((tiers.gold?["target"] as? Int) ?? 0)
                let progress = (tiers.bronze?["progress"] as? Double) ?? 0

                return PublicChallenge(
                    id: metric,
                    name: nameMap[metric] ?? metric,
                    category: categoryMap[metric] ?? "walking",
                    metric: metric,
                    bronzeTarget: bronzeTarget,
                    silverTarget: silverTarget,
                    goldTarget: goldTarget,
                    joined: true,
                    progress: progress
                )
            }
        } catch {
            // Silent fail - not critical
        }
    }

    private func formatWeeklyProgress(_ value: Double, unit: String) -> String {
        if unit == "km" || unit == "hrs" {
            return String(format: "%.1f %@", value, unit)
        }
        return "\(Int(value)) \(unit)"
    }

    // MARK: - Completed Section

    private var completedSection: some View {
        Group {
            SectionHeader(title: "Completed Challenges", icon: "checkmark.circle.fill")

            if viewModel.completedChallenges.isEmpty {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    message: "No completed challenges",
                    subtitle: "Challenges will appear here once they finish"
                )
            } else {
                ForEach(viewModel.completedChallenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        CompletedChallengeCard(challenge: challenge)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Won Section

    private var wonSection: some View {
        Group {
            SectionHeader(title: "Challenges Won", icon: "trophy.fill")

            if viewModel.wonChallenges.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    message: "No wins yet",
                    subtitle: "Win challenges to see them here!"
                )
            } else {
                ForEach(viewModel.wonChallenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        CompletedChallengeCard(challenge: challenge, isWon: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Lost Section

    private var lostSection: some View {
        Group {
            SectionHeader(title: "Challenges Lost", icon: "xmark.circle.fill")

            if viewModel.lostChallenges.isEmpty {
                EmptyStateCard(
                    icon: "xmark.circle",
                    message: "No losses",
                    subtitle: "Keep up the good work!"
                )
            } else {
                ForEach(viewModel.lostChallenges) { challenge in
                    NavigationLink(destination: ChallengeDetailView(challenge: challenge)) {
                        CompletedChallengeCard(challenge: challenge, isWon: false)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }


// MARK: - Challenge Category

enum ChallengeCategory: CaseIterable {
    case active, completed, won, lost

    var title: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .won: return "Won"
        case .lost: return "Lost"
        }
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    let challenge: Challenge
    var position: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let metric = challenge.metricType {
                            Image(systemName: metric.icon)
                                .foregroundStyle(Color.agonAccent)
                        }
                        Text(challenge.metricType?.title ?? challenge.metric)
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Text("\(min(challenge.participants.count, 10))/10 participants - \(challenge.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
            }

            // Leaderboard position and stat
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "trophy")
                        .font(.caption)
                        .foregroundStyle(Color.agonAccent)
                    if let pos = position {
                        Text("#\(pos) of \(challenge.participants.count)")
                            .font(.caption.bold())
                            .foregroundStyle(Color.agonTextPrimary)
                    } else {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(challenge.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressForChallenge(_ challenge: Challenge) -> Double {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let start = formatter.date(from: challenge.startDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.startDate) ?? Date()
        }()

        let end = formatter.date(from: challenge.endDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.endDate) ?? Date()
        }()

        let totalDuration = end.timeIntervalSince(start)
        guard totalDuration > 0 else { return 0 }

        let elapsed = Date().timeIntervalSince(start)
        return min(1.0, max(0, elapsed / totalDuration))
    }

    private func daysElapsed(_ challenge: Challenge) -> Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let start = formatter.date(from: challenge.startDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.startDate) ?? Date()
        }()
        let elapsed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(1, elapsed + 1)
    }

    private func totalDays(_ challenge: Challenge) -> Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let start = formatter.date(from: challenge.startDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.startDate) ?? Date()
        }()
        let end = formatter.date(from: challenge.endDate) ?? {
            formatter.formatOptions = [.withInternetDateTime]
            return formatter.date(from: challenge.endDate) ?? Date()
        }()
        return max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }
}

// MARK: - Completed Challenge Card

struct CompletedChallengeCard: View {
    let challenge: Challenge
    var isWon: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let metric = challenge.metricType {
                            Image(systemName: metric.icon)
                                .foregroundStyle(isWon ? Color.agonAccent : Color.agonTextSecondary)
                        }
                        Text(challenge.metricType?.title ?? challenge.metric)
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Text("\(challenge.participants.count) participants • Ended")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
                if isWon {
                    Image(systemName: "trophy.fill")
                        .font(.title2)
                        .foregroundStyle(Color.agonAccent)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.agonTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Race Track Progress Bar (Feature 2)

struct RaceTrackProgressBar: View {
    let challenge: Challenge

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.agonBackground)
                        .frame(height: 20)

                    // Dashed lane lines
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.agonBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .frame(height: 20)

                    // Participant positions
                    ForEach(Array(challenge.participants.enumerated()), id: \.offset) { index, participantId in
                        let progress = participantProgress(for: index)
                        let xPos = progress * (geometry.size.width - 24)
                        let isCurrentUser = participantId == (AuthService.shared.currentUser?.id ?? "")

                        Circle()
                            .fill(isCurrentUser ? Color.agonAccent : Color.agonSecondary)
                            .frame(width: 18, height: 18)
                            .overlay {
                                Text(participantInitial(for: index))
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .offset(x: xPos)
                    }

                    // Finish line
                    Rectangle()
                        .fill(Color.agonTextPrimary)
                        .frame(width: 2, height: 20)
                        .position(x: geometry.size.width - 1, y: 10)
                }
            }
            .frame(height: 20)
        }
    }

    private func participantProgress(for index: Int) -> Double {
        // Distribute participants evenly based on index for visual effect
        // In a real scenario this would come from API scores
        let base = 0.3
        let spread = 0.4
        let position = base + (spread * Double(index) / max(1, Double(challenge.participants.count - 1)))
        return min(0.95, position + Double.random(in: -0.1...0.1))
    }

    private func participantInitial(for index: Int) -> String {
        if index == 0 { return "Y" }
        return "\(index)"
    }
}

// MARK: - Invited Challenge Card

struct InvitedChallengeCard: View {
    let challenge: Challenge
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if let metric = challenge.metricType {
                            Image(systemName: metric.icon)
                                .foregroundStyle(Color.agonAccent)
                        }
                        Text(challenge.metricType?.title ?? challenge.metric)
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                    }
                    Text("\(challenge.participants.count) participants • \(challenge.daysRemaining) days left")
                        .font(.caption)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                Spacer()
                Button(action: onJoin) {
                    Text("Join")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.agonAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let message: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(Color.agonTextSecondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.agonTextSecondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color.agonAccent)
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.agonTextPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ChallengesView()
    }
}
