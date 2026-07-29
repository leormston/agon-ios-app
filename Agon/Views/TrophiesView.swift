import SwiftUI

// MARK: - Trophy Model

struct Trophy: Identifiable {
    let id: String
    let challengeName: String
    let tier: String
    let awardedAt: String?
    let category: String

    var isEarned: Bool { awardedAt != nil }

    var tierColor: Color {
        switch tier.lowercased() {
        case "gold": return Color(red: 255/255, green: 215/255, blue: 0/255)
        case "silver": return Color.gray
        case "bronze": return Color(red: 205/255, green: 127/255, blue: 50/255)
        default: return Color.agonBorder
        }
    }

    var tierIcon: String { "trophy.fill" }
}

// MARK: - Trophies View

struct TrophiesView: View {
    let userId: String?
    @State private var trophies: [Trophy] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    init(userId: String? = nil) {
        self.userId = userId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Stats header
                if !trophies.isEmpty {
                    HStack(spacing: 0) {
                        trophyStat(count: trophies.filter { $0.isEarned && $0.tier == "gold" }.count, label: "Gold", color: Color(red: 255/255, green: 215/255, blue: 0/255))
                        trophyStat(count: trophies.filter { $0.isEarned && $0.tier == "silver" }.count, label: "Silver", color: .gray)
                        trophyStat(count: trophies.filter { $0.isEarned && $0.tier == "bronze" }.count, label: "Bronze", color: Color(red: 205/255, green: 127/255, blue: 50/255))
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if isLoading {
                    ProgressView("Loading trophies...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if trophies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("No trophies yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text("Join public challenges to earn trophies!")
                            .font(.caption)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Grid of trophies
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(trophies) { trophy in
                            trophyCell(trophy)
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
        .navigationTitle("Trophies")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTrophies()
        }
        .refreshable {
            await loadTrophies()
        }
    }

    // MARK: - Trophy Cell

    private func trophyCell(_ trophy: Trophy) -> some View {
        VStack(spacing: 8) {
            Image(systemName: trophy.tierIcon)
                .font(.title)
                .foregroundStyle(trophy.isEarned ? trophy.tierColor : Color.agonBorder.opacity(0.5))

            Text(trophy.challengeName)
                .font(.caption2)
                .foregroundStyle(trophy.isEarned ? Color.agonTextPrimary : Color.agonTextSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(trophy.tier.capitalized)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(trophy.isEarned ? trophy.tierColor : Color.agonBorder)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color.agonSurface.opacity(trophy.isEarned ? 1 : 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(trophy.isEarned ? trophy.tierColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Stat

    private func trophyStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.caption)
                    .foregroundStyle(color)
                Text("\(count)")
                    .font(.title3.bold())
                    .foregroundStyle(Color.agonTextPrimary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color.agonTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Load

    private func loadTrophies() async {
        isLoading = true
        errorMessage = nil

        do {
            let targetUserId = userId ?? AuthService.shared.currentUser?.id ?? ""
            let raw = try await APIService.shared.getTrophies(userId: targetUserId)

            trophies = raw.compactMap { dict -> Trophy? in
                guard let id = dict["id"] as? String ?? dict["challengeId"] as? String else { return nil }
                let name = dict["challengeName"] as? String ?? dict["name"] as? String ?? "Challenge"
                let tier = dict["tier"] as? String ?? "bronze"
                let awarded = dict["awardedAt"] as? String
                let category = dict["category"] as? String ?? ""

                return Trophy(
                    id: "\(id)-\(tier)",
                    challengeName: name,
                    tier: tier,
                    awardedAt: awarded,
                    category: category
                )
            }

            // Also check for new trophies
            if userId == nil {
                _ = try? await APIService.shared.checkTrophies()
            }
        } catch {
            errorMessage = "Failed to load trophies"
            print("Trophies error: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        TrophiesView()
    }
}
