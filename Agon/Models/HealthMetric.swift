import Foundation

// MARK: - Health Metric Types

enum HealthMetricType: String, CaseIterable, Identifiable {
    case steps
    case distanceWalked
    case distanceRan
    case totalSleep
    case timeInDaylight
    case exerciseMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: return "Steps"
        case .distanceWalked: return "Distance Walked"
        case .distanceRan: return "Distance Ran"
        case .totalSleep: return "Total Sleep"
        case .timeInDaylight: return "Daylight"
        case .exerciseMinutes: return "Exercise"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distanceWalked: return "figure.walk.motion"
        case .distanceRan: return "figure.run"
        case .totalSleep: return "moon.fill"
        case .timeInDaylight: return "sun.max.fill"
        case .exerciseMinutes: return "flame.fill"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distanceWalked: return "km"
        case .distanceRan: return "km"
        case .totalSleep: return "hrs"
        case .timeInDaylight: return "min"
        case .exerciseMinutes: return "min"
        }
    }
}

// MARK: - Health Metric Value

struct HealthMetric: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let value: Double
    let date: Date

    var formattedValue: String {
        switch type {
        case .steps:
            return Int(value).formatted(.number)
        case .distanceWalked, .distanceRan:
            return String(format: "%.2f", value)
        case .totalSleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .timeInDaylight:
            return "\(Int(value))"
        case .exerciseMinutes:
            return "\(Int(value))"
        }
    }
}

// MARK: - Daily Snapshot

struct DailySnapshot: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Double
    let distanceWalked: Double
    let distanceRan: Double
    let totalSleep: Double
    let timeInDaylight: Double
    let exerciseMinutes: Double

    var metrics: [HealthMetric] {
        [
            HealthMetric(type: .steps, value: steps, date: date),
            HealthMetric(type: .distanceWalked, value: distanceWalked, date: date),
            HealthMetric(type: .distanceRan, value: distanceRan, date: date),
            HealthMetric(type: .totalSleep, value: totalSleep, date: date),
            HealthMetric(type: .timeInDaylight, value: timeInDaylight, date: date),
            HealthMetric(type: .exerciseMinutes, value: exerciseMinutes, date: date),
        ]
    }
}
