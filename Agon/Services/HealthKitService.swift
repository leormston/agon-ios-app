import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {

    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var authorizationError: String?

    // MARK: - Authorization

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []

        // Quantity types
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .appleExerciseTime,
            .timeInDaylight,
        ]

        for identifier in quantityIdentifiers {
            if let type = HKQuantityType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        // Category types
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        // Workout type (for distinguishing walking vs running distance)
        types.insert(HKObjectType.workoutType())

        return types
    }

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            authorizationError = "HealthKit is not available on this device."
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    // MARK: - Fetch Steps

    func fetchSteps(for date: Date = .now) async -> Double {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        return await fetchCumulativeSum(for: stepsType, date: date, unit: .count())
    }

    // MARK: - Fetch Distance Walked

    func fetchDistanceWalked(for date: Date = .now) async -> Double {
        let totalDistance = await fetchTotalWalkingRunningDistance(for: date)
        let runDistance = await fetchRunningWorkoutDistance(for: date)
        // Walking distance = total - running
        let walkDistance = max(totalDistance - runDistance, 0)
        return walkDistance
    }

    // MARK: - Fetch Distance Ran

    func fetchDistanceRan(for date: Date = .now) async -> Double {
        return await fetchRunningWorkoutDistance(for: date)
    }

    // MARK: - Fetch Total Sleep (hours)

    func fetchSleep(for date: Date = .now) async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }

        // Sleep is logged overnight - look from 6pm previous day to end of current day
        let calendar = Calendar.current
        let endOfDay = calendar.startOfDay(for: date).addingTimeInterval(86400)
        let startOfPreviousEvening = calendar.startOfDay(for: date).addingTimeInterval(-6 * 3600)

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfPreviousEvening,
            end: endOfDay,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                guard let samples = results as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]

                let totalSeconds = samples
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: totalSeconds / 3600.0)
            }
            self.healthStore.execute(query)
        }
    }

    // MARK: - Fetch Time in Daylight (minutes)

    func fetchTimeInDaylight(for date: Date = .now) async -> Double {
        guard let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) else { return 0 }
        return await fetchCumulativeSum(for: daylightType, date: date, unit: .minute())
    }

    // MARK: - Fetch Exercise Minutes

    func fetchExerciseMinutes(for date: Date = .now) async -> Double {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return 0 }
        return await fetchCumulativeSum(for: exerciseType, date: date, unit: .minute())
    }

    // MARK: - Fetch Full Snapshot

    func fetchTodaySnapshot() async -> DailySnapshot {
        let today = Date.now

        async let steps = fetchSteps(for: today)
        async let distanceWalked = fetchDistanceWalked(for: today)
        async let distanceRan = fetchDistanceRan(for: today)
        async let sleep = fetchSleep(for: today)
        async let daylight = fetchTimeInDaylight(for: today)
        async let exercise = fetchExerciseMinutes(for: today)

        return await DailySnapshot(
            date: today,
            steps: steps,
            distanceWalked: distanceWalked,
            distanceRan: distanceRan,
            totalSleep: sleep,
            timeInDaylight: daylight,
            exerciseMinutes: exercise
        )
    }

    // MARK: - Helpers

    private func fetchCumulativeSum(for quantityType: HKQuantityType, date: Date, unit: HKUnit) async -> Double {
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                guard let sum = result?.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            self.healthStore.execute(query)
        }
    }

    /// Total walking + running distance for the day (in km)
    private func fetchTotalWalkingRunningDistance(for date: Date) async -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return 0 }
        let meters = await fetchCumulativeSum(for: distanceType, date: date, unit: .meter())
        return meters / 1000.0
    }

    /// Distance from running workouts only (in km)
    private func fetchRunningWorkoutDistance(for date: Date) async -> Double {
        let (start, end) = dayBounds(for: date)

        let datePredicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        let runningPredicate = HKQuery.predicateForWorkouts(with: .running)
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, runningPredicate])

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: compound,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                guard let workouts = results as? [HKWorkout] else {
                    continuation.resume(returning: 0)
                    return
                }

                let totalMeters = workouts.reduce(0.0) { total, workout in
                    total + (workout.totalDistance?.doubleValue(for: .meter()) ?? 0)
                }

                continuation.resume(returning: totalMeters / 1000.0)
            }
            self.healthStore.execute(query)
        }
    }

    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
