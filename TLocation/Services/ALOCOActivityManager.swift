import ActivityKit
import Foundation

@MainActor
enum ALOCOActivityManager {
    private static var current: Activity<ALOCOActivityAttributes>?
    private static var lastUpdate = Date.distantPast
    private static var generation = 0

    static func startLocation(destination: String = "Selected point") {
        start(destination: destination, state: .init(mode: "location", progress: 0, speedMPH: 0, etaMinutes: 0, milesDriven: 0))
    }

    static func startDrive(destination: String, speedMPH: Int, etaMinutes: Int) {
        start(destination: destination, state: .init(mode: "drive", progress: 0, speedMPH: speedMPH, etaMinutes: etaMinutes, milesDriven: 0))
    }

    private static func start(destination: String, state: ALOCOActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        generation += 1
        let token = generation
        Task {
            await endExisting()
            guard token == generation else { return }
            do {
                current = try Activity.request(
                    attributes: ALOCOActivityAttributes(destination: destination),
                    content: ActivityContent(state: state, staleDate: nil),
                    pushType: nil
                )
                lastUpdate = .now
            } catch {
                // Live Activities may be disabled by the user; simulation remains usable.
            }
        }
    }

    static func updateDrive(progress: Double, speedMPH: Int, etaMinutes: Int, milesDriven: Double) {
        guard Date().timeIntervalSince(lastUpdate) >= 10 || progress >= 1 else { return }
        lastUpdate = .now
        let state = ALOCOActivityAttributes.ContentState(
            mode: "drive", progress: progress, speedMPH: speedMPH,
            etaMinutes: etaMinutes, milesDriven: milesDriven
        )
        Task { await current?.update(ActivityContent(state: state, staleDate: nil)) }
    }

    private static func endExisting() async {
        let activities = Activity<ALOCOActivityAttributes>.activities
        current = nil
        for activity in activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    static func stop() {
        generation += 1
        Task { await endExisting() }
    }
}
