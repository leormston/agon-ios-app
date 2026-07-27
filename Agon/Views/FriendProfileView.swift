import SwiftUI

struct FriendProfileView: View {
    let userId: String
    let displayName: String

    @State private var profile: [String: Any]?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPeriod: DashboardPeriod = .today
    @State private var aggregationMode: AggregationMode = .total

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(Color.agonTextSecondary)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(Color.agonTextSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    // Avatar & Name
                    VStack(spacing: 12) {
                        avatarView
                            .frame(width: 80, height: 80)

                        Text(profileDisplayName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.agonTextPrimary)

                        if let memberSince = memberSinceText {
                            Text("Member since \(memberSince)")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Active Challenges
                    HStack {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color.agonAccent)
                        Text("Active Challenges")
                            .font(.headline)
                            .foregroundStyle(Color.agonTextPrimary)
                        Spacer()
                        Text("\(activeChallengesCount)")
                            .font(.title3.bold())
                            .foregroundStyle(Color.agonAccent)
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Period Tabs
                    HStack(spacing: 0) {
                        PeriodTab(title: "Today", isSelected: selectedPeriod == .today) {
                            selectedPeriod = .today
                            aggregationMode = .total
                        }
                        PeriodTab(title: "Last 7 Days", isSelected: selectedPeriod == .last7Days) {
                            selectedPeriod = .last7Days
                            aggregationMode = .total
                        }
                        PeriodTab(title: "This Week", isSelected: selectedPeriod == .thisWeek) {
                            selectedPeriod = .thisWeek
                            aggregationMode = .total
                        }
                    }
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Total / Average toggle
                    if selectedPeriod != .today {
                        HStack(spacing: 0) {
                            Button { aggregationMode = .total } label: {
                                Text("Total")
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(aggregationMode == .total ? Color.agonAccent : Color.clear)
                                    .foregroundStyle(aggregationMode == .total ? .white : Color.agonTextSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Button { aggregationMode = .average } label: {
                                Text("Average")
                                    .font(.caption.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(aggregationMode == .average ? Color.agonAccent : Color.clear)
                                    .foregroundStyle(aggregationMode == .average ? .white : Color.agonTextSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .background(Color.agonSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Health Comparison
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color.agonAccent)
                            Text("Health Stats")
                                .font(.headline)
                                .foregroundStyle(Color.agonTextPrimary)
                            Spacer()
                            if selectedPeriod != .today {
                                Text(aggregationMode == .total ? "Totals" : "Daily Avg")
                                    .font(.caption)
                                    .foregroundStyle(Color.agonTextSecondary)
                            }
                        }

                        if hasHealthData {
                            VStack(spacing: 12) {
                                comparisonRow(icon: "figure.walk", label: "Steps", theirValue: getTheirValue("steps"), yourValue: getYourValue("steps"), unit: "")
                                comparisonRow(icon: "flame.fill", label: "Exercise", theirValue: getTheirValue("exerciseMinutes"), yourValue: getYourValue("exerciseMinutes"), unit: " min")
                                comparisonRow(icon: "figure.walk.motion", label: "Distance", theirValue: getTheirDistance(), yourValue: getYourDistance(), unit: " km")
                                comparisonRow(icon: "moon.fill", label: "Sleep", theirValue: getTheirValue("totalSleep"), yourValue: getYourValue("totalSleep"), unit: " hrs")
                                comparisonRow(icon: "sun.max.fill", label: "Daylight", theirValue: getTheirValue("timeInDaylight"), yourValue: getYourValue("timeInDaylight"), unit: " min")
                            }
                        } else {
                            Text("No health data available")
                                .font(.caption)
                                .foregroundStyle(Color.agonTextSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(Color.agonSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
        .background(Color.agonBackground)
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadProfile()
        }
        .task {
            await loadProfile()
        }
    }

    // MARK: - Comparison Row

    private func comparisonRow(icon: String, label: String, theirValue: Double, yourValue: Double, unit: String) -> some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(Color.agonAccent)
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(Color.agonTextPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                // Theirs
                VStack(spacing: 2) {
                    Text(formatValue(theirValue, unit: unit))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text("Them")
                        .font(.caption2)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.agonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Comparison indicator
                Image(systemName: yourValue > theirValue ? "arrow.up.circle.fill" : yourValue < theirValue ? "arrow.down.circle.fill" : "equal.circle.fill")
                    .foregroundStyle(yourValue >= theirValue ? Color.agonAccent : Color.agonTextSecondary)

                // Yours
                VStack(spacing: 2) {
                    Text(formatValue(yourValue, unit: unit))
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.agonTextPrimary)
                    Text("You")
                        .font(.caption2)
                        .foregroundStyle(Color.agonTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.agonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func formatValue(_ value: Double, unit: String) -> String {
        if unit == " km" {
            return String(format: "%.1f%@", value, unit)
        } else if unit == " hrs" {
            return String(format: "%.1f%@", value, unit)
        } else if value >= 1000 {
            return "\(Int(value).formatted(.number))\(unit)"
        }
        return "\(Int(value))\(unit)"
    }

    // MARK: - Get Values

    private func getTheirValue(_ key: String) -> Double {
        let snapshots = getSnapshotsForPeriod()
        guard !snapshots.isEmpty else { return 0 }
        let total = snapshots.reduce(0.0) { sum, snap in
            let metrics = snap["metrics"] as? [String: Any] ?? snap
            return sum + ((metrics[key] as? Double) ?? Double((metrics[key] as? Int) ?? 0))
        }
        return aggregationMode == .average ? total / Double(snapshots.count) : total
    }

    private func getTheirDistance() -> Double {
        let snapshots = getSnapshotsForPeriod()
        guard !snapshots.isEmpty else { return 0 }
        let total = snapshots.reduce(0.0) { sum, snap in
            let metrics = snap["metrics"] as? [String: Any] ?? snap
            let walked = (metrics["distanceWalked"] as? Double) ?? 0
            let ran = (metrics["distanceRan"] as? Double) ?? 0
            return sum + walked + ran
        }
        return aggregationMode == .average ? total / Double(snapshots.count) : total
    }

    private func getYourValue(_ key: String) -> Double {
        let snapshots = getYourSnapshotsForPeriod()
        guard !snapshots.isEmpty else { return 0 }
        let total = snapshots.reduce(0.0) { sum, snap in
            let metrics = snap["metrics"] as? [String: Any] ?? snap
            return sum + ((metrics[key] as? Double) ?? Double((metrics[key] as? Int) ?? 0))
        }
        return aggregationMode == .average ? total / Double(snapshots.count) : total
    }

    private func getYourDistance() -> Double {
        let snapshots = getYourSnapshotsForPeriod()
        guard !snapshots.isEmpty else { return 0 }
        let total = snapshots.reduce(0.0) { sum, snap in
            let metrics = snap["metrics"] as? [String: Any] ?? snap
            let walked = (metrics["distanceWalked"] as? Double) ?? 0
            let ran = (metrics["distanceRan"] as? Double) ?? 0
            return sum + walked + ran
        }
        return aggregationMode == .average ? total / Double(snapshots.count) : total
    }

    private func getSnapshotsForPeriod() -> [[String: Any]] {
        guard let snapshots = profile?["recentSnapshots"] as? [[String: Any]] else { return [] }
        let dates = datesForPeriod()
        return snapshots.filter { snap in
            guard let date = snap["date"] as? String else { return false }
            return dates.contains(date)
        }
    }

    private func getYourSnapshotsForPeriod() -> [[String: Any]] {
        guard let snapshots = profile?["yourSnapshots"] as? [[String: Any]] else { return [] }
        let dates = datesForPeriod()
        return snapshots.filter { snap in
            guard let date = snap["date"] as? String else { return false }
            return dates.contains(date)
        }
    }

    private func datesForPeriod() -> Set<String> {
        let calendar = Calendar.current
        let today = Date.now
        let utcFormatter = DateFormatter()
        utcFormatter.dateFormat = "yyyy-MM-dd"
        utcFormatter.timeZone = TimeZone(identifier: "UTC")
        let localFormatter = DateFormatter()
        localFormatter.dateFormat = "yyyy-MM-dd"
        localFormatter.timeZone = .current

        switch selectedPeriod {
        case .today:
            // Include both UTC and local date to handle timezone boundary
            return [utcFormatter.string(from: today), localFormatter.string(from: today)]
        case .last7Days:
            var dates = Set<String>()
            for i in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                dates.insert(utcFormatter.string(from: date))
                dates.insert(localFormatter.string(from: date))
            }
            return dates
        case .thisWeek:
            let weekday = calendar.component(.weekday, from: today)
            let daysSinceMonday = (weekday + 5) % 7
            var dates = Set<String>()
            for i in 0...daysSinceMonday {
                let date = calendar.date(byAdding: .day, value: -i, to: today)!
                dates.insert(utcFormatter.string(from: date))
                dates.insert(localFormatter.string(from: date))
            }
            return dates
        }
    }

    // MARK: - Avatar

    @ViewBuilder
    private var avatarView: some View {
        if let avatarUrl = profile?["avatarUrl"] as? String, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                initialCircle
            }
            .clipShape(Circle())
        } else {
            initialCircle
        }
    }

    private var initialCircle: some View {
        Circle()
            .fill(Color.agonAccent.opacity(0.2))
            .overlay {
                Text(String(profileDisplayName.prefix(1)).uppercased())
                    .font(.title.bold())
                    .foregroundStyle(Color.agonAccent)
            }
    }

    // MARK: - Computed Properties

    private var profileDisplayName: String {
        (profile?["displayName"] as? String) ?? displayName
    }

    private var memberSinceText: String? {
        guard let createdAt = profile?["createdAt"] as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: createdAt)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: createdAt)
        }
        guard let parsedDate = date else { return nil }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM yyyy"
        return displayFormatter.string(from: parsedDate)
    }

    private var activeChallengesCount: Int {
        (profile?["activeChallengesCount"] as? Int) ?? 0
    }

    private var hasHealthData: Bool {
        guard let snapshots = profile?["recentSnapshots"] as? [[String: Any]] else { return false }
        return !snapshots.isEmpty
    }

    // MARK: - Load

    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await APIService.shared.getUserProfile(userId: userId)
            if profile == nil {
                errorMessage = "Profile not found"
            }
        } catch is CancellationError {
            // Ignore - task cancelled by SwiftUI
        } catch let error as NSError where error.code == -999 {
            // Ignore - URLSession request cancelled
        } catch {
            if profile == nil {
                errorMessage = "Failed to load profile"
            }
            print("Load profile error: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Period Tab

struct PeriodTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.agonAccent : Color.clear)
                .foregroundStyle(isSelected ? .white : Color.agonTextSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

#Preview {
    NavigationStack {
        FriendProfileView(userId: "test-user-id", displayName: "John")
    }
}
