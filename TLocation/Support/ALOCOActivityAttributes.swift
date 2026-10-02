import ActivityKit
import Foundation

struct ALOCOActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let mode: String
        let progress: Double
        let speedMPH: Int
        let etaMinutes: Int
        let milesDriven: Double
    }

    let destination: String
}
