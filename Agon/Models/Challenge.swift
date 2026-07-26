import Foundation

// MARK: - Challenge Metric

enum ChallengeMetric: String, CaseIterable, Identifiable {
    case steps
    case exerciseMinutes
    case distanceWalked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: return "Steps"
        case .exerciseMinutes: return "Exercise Minutes"
        case .distanceWalked: return "Distance Walked"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .exerciseMinutes: return "flame.fill"
        case .distanceWalked: return "figure.walk.motion"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .exerciseMinutes: return "min"
        case .distanceWalked: return "km"
        }
    }
}

// MARK: - Challenge Duration

enum ChallengeDuration: String, CaseIterable, Identifiable {
    case oneDay = "1d"
    case oneWeek = "1w"
    case oneMonth = "1m"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneDay: return "1 Day"
        case .oneWeek: return "1 Week"
        case .oneMonth: return "1 Month"
        }
    }
}

// MARK: - Challenge Status

enum ChallengeStatus: String, Codable {
    case active
    case completed
}

// MARK: - Challenge Model

struct Challenge: Identifiable, Codable {
    let id: String
    let creatorId: String
    let metric: String
    let startDate: String
    let endDate: String
    let status: String
    let participants: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id = "challengeId"
        case creatorId
        case metric
        case startDate
        case endDate
        case status
        case participants
        case createdAt
    }

    var metricType: ChallengeMetric? {
        ChallengeMetric(rawValue: metric)
    }

    var isActive: Bool {
        status == ChallengeStatus.active.rawValue
    }

    var daysRemaining: Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let end = formatter.date(from: endDate) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let end = formatter.date(from: endDate) else { return 0 }
            return max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
        }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0)
    }
}
