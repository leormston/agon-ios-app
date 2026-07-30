import SwiftUI

// MARK: - Public Challenge Model

struct PublicChallenge: Identifiable {
    let id: String
    let name: String
    let category: String
    let metric: String
    let bronzeTarget: Double
    let silverTarget: Double
    let goldTarget: Double
    var joined: Bool
    var progress: Double

    var categoryType: PublicChallengeCategory {
        PublicChallengeCategory(rawValue: category) ?? .walking
    }

    var metricUnit: String {
        switch metric {
        case "steps": return "steps"
        case "distanceWalked", "distanceRan": return "km"
        case "totalSleep": return "hrs"
        case "timeInDaylight", "exerciseMinutes": return "min"
        default: return ""
        }
    }
}

enum PublicChallengeCategory: String, CaseIterable {
    case walking = "Walking"
    case distance = "Distance"
    case sleep = "Sleep"
    case running = "Running"
    case sun = "Sun"

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .distance: return "figure.walk.motion"
        case .sleep: return "moon.fill"
        case .running: return "figure.run"
        case .sun: return "sun.max.fill"
        }
    }
}

// MARK: - Public Challenges View

struct PublicChallengesView: View {
    @State private var challenges: [PublicChallenge] = []
    @State private var isLoading = true
    @State private var joiningId: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading challenges...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if challenges.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No public challenges available")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(PublicChallengeCategory.allCases, id: \.rawValue) { category in
                        let categoryChallenges = challenges.filter { $0.categoryType == category }
                        if !categoryChallenges.isEmpty {
                            categorySection(category: category, challenges: categoryChallenges)
                        }
                    }
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle("Public Challenges")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadChallenges()
        }
        .refreshable {
            await loadChallenges()
        }
    }

    // MARK: - Category Section

    private func categorySection(category: PublicChallengeCategory, challenges: [PublicChallenge]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundStyle(Color.agonAccent)
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
            }

            ForEach(challenges) { challenge in
                publicChallengeCard(challenge)
            }
        }
    }

    // MARK: - Challenge Card

    private func publicChallengeCard(_ challenge: PublicChallenge) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(challenge.name)
                .font(.subheadline.bold())
                .foregroundStyle(Color.agonTextPrimary)

            // Trophy tiers
            HStack(spacing: 16) {
                trophyTier(label: "Bronze", target: challenge.bronzeTarget, unit: challenge.metricUnit, color: Color(red: 205/255, green: 127/255, blue: 50/255))
                trophyTier(label: "Silver", target: challenge.silverTarget, unit: challenge.metricUnit, color: Color.gray)
                trophyTier(label: "Gold", target: challenge.goldTarget, unit: challenge.metricUnit, color: Color(red: 255/255, green: 215/255, blue: 0/255))
            }

            // Progress or Join
            if challenge.joined {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                        Spacer()
                        Text(formatProgress(challenge.progress, unit: challenge.metricUnit))
                            .font(.caption.bold())
                            .foregroundStyle(Color.agonAccent)
                    }
                    ProgressView(value: min(1.0, challenge.progress / challenge.goldTarget))
                        .tint(progressColor(for: challenge))
                }
            } else {
                Button {
                    Task { await joinChallenge(challenge) }
                } label: {
                    HStack {
                        if joiningId == challenge.id {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Join Challenge")
                                .font(.caption.bold())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.agonAccent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(joiningId != nil)
            }
        }
        .padding()
        .background(Color.agonSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Trophy Tier

    private func trophyTier(label: String, target: Double, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(Color.agonTextSecondary)
            Text(formatTarget(target, unit: unit))
                .font(.caption2)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func formatTarget(_ value: Double, unit: String) -> String {
        if unit == "km" || unit == "hrs" {
            return String(format: "%.1f %@", value, unit)
        }
        return "\(Int(value)) \(unit)"
    }

    private func formatProgress(_ value: Double, unit: String) -> String {
        if unit == "km" || unit == "hrs" {
            return String(format: "%.1f %@", value, unit)
        }
        return "\(Int(value)) \(unit)"
    }

    private func progressColor(for challenge: PublicChallenge) -> Color {
        if challenge.progress >= challenge.goldTarget {
            return Color(red: 255/255, green: 215/255, blue: 0/255)
        } else if challenge.progress >= challenge.silverTarget {
            return .gray
        } else if challenge.progress >= challenge.bronzeTarget {
            return Color(red: 205/255, green: 127/255, blue: 50/255)
        }
        return Color.agonAccent
    }

    // MARK: - API

    private func loadChallenges() async {
        isLoading = true
        errorMessage = nil

        do {
            let raw = try await APIService.shared.getPublicChallenges()

            // API returns individual challenges per tier - group by metric
            var grouped: [String: (bronze: [String: Any]?, silver: [String: Any]?, gold: [String: Any]?)] = [:]

            for dict in raw {
                guard let metric = dict["metric"] as? String,
                      let tier = dict["tier"] as? String else { continue }

                if grouped[metric] == nil {
                    grouped[metric] = (bronze: nil, silver: nil, gold: nil)
                }
                switch tier {
                case "bronze": grouped[metric]?.bronze = dict
                case "silver": grouped[metric]?.silver = dict
                case "gold": grouped[metric]?.gold = dict
                default: break
                }
            }

            let categoryMap: [String: String] = [
                "steps": "walking",
                "distanceWalked": "distance",
                "totalSleep": "sleep",
                "distanceRan": "running",
                "timeInDaylight": "sun"
            ]

            challenges = grouped.compactMap { metric, tiers -> PublicChallenge? in
                let bronze = tiers.bronze
                let silver = tiers.silver
                let gold = tiers.gold

                let bronzeTarget = (bronze?["target"] as? Double) ?? Double((bronze?["target"] as? Int) ?? 0)
                let silverTarget = (silver?["target"] as? Double) ?? Double((silver?["target"] as? Int) ?? 0)
                let goldTarget = (gold?["target"] as? Double) ?? Double((gold?["target"] as? Int) ?? 0)
                let joined = (bronze?["joined"] as? Bool) ?? (silver?["joined"] as? Bool) ?? (gold?["joined"] as? Bool) ?? false

                let name: String
                switch metric {
                case "steps": name = "Walker"
                case "distanceWalked": name = "Hiker"
                case "totalSleep": name = "Sleeper"
                case "distanceRan": name = "Runner"
                case "timeInDaylight": name = "Sun Seeker"
                default: name = metric
                }

                return PublicChallenge(
                    id: metric,
                    name: name,
                    category: categoryMap[metric] ?? "walking",
                    metric: metric,
                    bronzeTarget: bronzeTarget,
                    silverTarget: silverTarget,
                    goldTarget: goldTarget,
                    joined: joined,
                    progress: 0
                )
            }.sorted { $0.category < $1.category }
        } catch is CancellationError {
            // Ignore
        } catch let error as NSError where error.code == -999 {
            // Ignore cancelled requests
        } catch {
            errorMessage = "Failed to load challenges"
            print("Public challenges error: \(error)")
        }

        isLoading = false
    }

    private func joinChallenge(_ challenge: PublicChallenge) async {
        joiningId = challenge.id

        // Join all three tiers for this metric
        let tierPrefixes: [String: String] = [
            "steps": "walker",
            "distanceWalked": "hiker",
            "totalSleep": "sleeper",
            "distanceRan": "runner",
            "timeInDaylight": "sun"
        ]

        guard let prefix = tierPrefixes[challenge.metric] else {
            errorMessage = "Failed to join challenge"
            joiningId = nil
            return
        }

        do {
            try await APIService.shared.joinPublicChallenge(id: "bronze-\(prefix)")
            try await APIService.shared.joinPublicChallenge(id: "silver-\(prefix)")
            try await APIService.shared.joinPublicChallenge(id: "gold-\(prefix)")
            if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
                challenges[index].joined = true
            }
        } catch {
            errorMessage = "Failed to join challenge"
        }

        joiningId = nil
    }
}

#Preview {
    NavigationStack {
        PublicChallengesView()
    }
}
