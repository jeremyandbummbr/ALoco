import WidgetKit
import SwiftUI
import ActivityKit

@main
struct ALOCOActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ALOCOActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 14) {
                    IsraelOutline()
                        .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 36, height: 66)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALoco")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.blue)
                        Text(context.state.mode == "drive"
                             ? "Driving to \(context.attributes.destination) now"
                             : "Location is on")
                            .font(.system(size: 20, weight: .semibold))
                            .lineLimit(2)
                    }
                }
                if context.state.mode == "drive" {
                    HStack(spacing: 6) {
                        Circle().fill(.blue.opacity(0.4)).frame(width: 9, height: 9)
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.blue.opacity(0.18)).frame(height: 5)
                                Capsule().fill(.blue).frame(width: geometry.size.width * context.state.progress, height: 5)
                                Image(systemName: "car.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.blue)
                                    .offset(x: max(0, geometry.size.width - 20) * context.state.progress)
                            }
                        }.frame(height: 24)
                        Circle().fill(.blue).frame(width: 9, height: 9)
                    }
                    HStack {
                        Text(String(format: "%.1f mi", context.state.milesDriven))
                        Spacer()
                        Text("\(context.state.speedMPH) mph")
                        Spacer()
                        Text("ETA \(context.state.etaMinutes)m")
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded).monospacedDigit())
                } else {
                    Text("Open ALoco to change or stop your location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(18)
            .activityBackgroundTint(.white)
            .activitySystemActionForegroundColor(.blue)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("ALoco").font(.headline).foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.mode == "drive" ? "\(context.state.etaMinutes)m" : "On")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.mode == "drive" {
                        Text("Driving to \(context.attributes.destination) now").lineLimit(1)
                        ProgressView(value: context.state.progress)
                            .tint(.cyan)
                        Text("\(context.state.speedMPH) mph · \(String(format: "%.1f", context.state.milesDriven)) mi")
                            .font(.caption)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.mode == "drive" ? "car.fill" : "location.fill")
            } compactTrailing: {
                Text(context.state.mode == "drive" ? "\(context.state.etaMinutes)m" : "On")
            } minimal: {
                Image(systemName: "location.fill")
            }
        }
    }
}
