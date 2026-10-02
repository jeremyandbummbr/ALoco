import SwiftUI
import MapKit
import CoreLocation

/// A road route plus distances along its actual geometry. Progress uses elapsed
/// wall time, so a delayed background timer catches up instead of slowing down.
struct DriveRoutePlan {
    struct SpeedZone {
        let endMeters: Double
        let speedMPH: Double
    }

    let routes: [MKRoute]
    let startName: String
    let destinationName: String
    let stopNames: [String]
    let stopCoordinates: [CLLocationCoordinate2D]
    let coordinates: [CLLocationCoordinate2D]
    let cumulativeMeters: [Double]
    let distanceMeters: Double
    let speedZones: [SpeedZone]

    init?(routes: [MKRoute], startName: String, destinationName: String, stopNames: [String]) {
        guard !routes.isEmpty else { return nil }
        var points: [CLLocationCoordinate2D] = []
        for route in routes {
            let polyline = route.polyline
            guard polyline.pointCount >= 2 else { return nil }
            var legPoints = Array(repeating: CLLocationCoordinate2D(latitude: 0, longitude: 0), count: polyline.pointCount)
            polyline.getCoordinates(&legPoints, range: NSRange(location: 0, length: polyline.pointCount))
            points.append(contentsOf: legPoints)
        }
        var cumulative = [0.0]
        cumulative.reserveCapacity(points.count)
        for index in 1..<points.count {
            let a = CLLocation(latitude: points[index - 1].latitude, longitude: points[index - 1].longitude)
            let b = CLLocation(latitude: points[index].latitude, longitude: points[index].longitude)
            cumulative.append(cumulative[index - 1] + a.distance(from: b))
        }
        guard let total = cumulative.last, total > 50 else { return nil }
        self.routes = routes
        self.startName = startName
        self.destinationName = destinationName
        self.stopNames = stopNames
        self.stopCoordinates = routes.dropLast().map { route in
            var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            route.polyline.getCoordinates(&coordinate, range: NSRange(location: route.polyline.pointCount - 1, length: 1))
            return coordinate
        }
        self.coordinates = points
        self.cumulativeMeters = cumulative
        self.distanceMeters = total

        // MapKit doesn't expose posted limits. Classify instruction text only
        // for a visibly labeled estimate, and retain fixed custom speed.
        let steps = routes.flatMap(\.steps).filter { $0.distance > 1 }
        let stepTotal = max(steps.reduce(0) { $0 + $1.distance }, 1)
        var stepDistance = 0.0
        self.speedZones = steps.map { step in
            stepDistance += step.distance
            let words = step.instructions.lowercased()
            let highway = words.contains("highway") || words.contains("freeway") ||
                words.contains("interstate") || words.contains("expressway") ||
                words.contains("motorway") || words.contains("ramp") ||
                words.range(of: #"\b(?:i|us)-?\d+\b"#, options: .regularExpression) != nil
            return SpeedZone(endMeters: min(total, stepDistance / stepTotal * total), speedMPH: highway ? 60 : 30)
        }
    }

    var start: CLLocationCoordinate2D { coordinates[0] }
    var destination: CLLocationCoordinate2D { coordinates[coordinates.count - 1] }

    /// Leave room for the floating route card at the bottom of the phone.
    var previewMapRect: MKMapRect {
        let bounds = routes.dropFirst().reduce(routes[0].polyline.boundingMapRect) {
            $0.union($1.polyline.boundingMapRect)
        }
        return MKMapRect(
            x: bounds.origin.x - bounds.width * 0.35,
            y: bounds.origin.y - bounds.height * 0.25,
            width: bounds.width * 1.7,
            height: bounds.height * 1.9
        )
    }

    func speedMPH(at meters: Double, fixedSpeedMPH: Double?) -> Double {
        if let fixedSpeedMPH { return fixedSpeedMPH }
        return speedZones.first(where: { meters < $0.endMeters })?.speedMPH ?? 30
    }

    func travelDistance(from startingMeters: Double, after seconds: TimeInterval, fixedSpeedMPH: Double?) -> Double {
        var position = startingMeters
        var remaining = max(0, seconds)
        while position < distanceMeters && remaining > 0 {
            let zoneEnd = fixedSpeedMPH == nil
                ? (speedZones.first(where: { position < $0.endMeters })?.endMeters ?? distanceMeters)
                : distanceMeters
            let speed = speedMPH(at: position, fixedSpeedMPH: fixedSpeedMPH) * 0.44704
            let segment = max(0, zoneEnd - position)
            let duration = segment / speed
            if remaining >= duration {
                position = zoneEnd
                remaining -= duration
            } else {
                position += remaining * speed
                remaining = 0
            }
        }
        return min(position, distanceMeters)
    }

    func remainingSeconds(from meters: Double, fixedSpeedMPH: Double?) -> Double {
        var position = meters
        var seconds = 0.0
        while position < distanceMeters {
            let end = fixedSpeedMPH == nil
                ? (speedZones.first(where: { position < $0.endMeters })?.endMeters ?? distanceMeters)
                : distanceMeters
            seconds += max(0, end - position) / (speedMPH(at: position, fixedSpeedMPH: fixedSpeedMPH) * 0.44704)
            position = end
        }
        return seconds
    }

    func coordinate(at traveledMeters: Double) -> CLLocationCoordinate2D {
        let target = min(max(0, traveledMeters), distanceMeters)
        if target <= 0 { return start }
        if target >= distanceMeters { return destination }

        var low = 1
        var high = cumulativeMeters.count - 1
        while low < high {
            let middle = (low + high) / 2
            if cumulativeMeters[middle] < target { low = middle + 1 }
            else { high = middle }
        }
        let segmentStart = cumulativeMeters[low - 1]
        let segmentLength = cumulativeMeters[low] - segmentStart
        guard segmentLength > 0 else { return coordinates[low] }
        let fraction = (target - segmentStart) / segmentLength
        let a = coordinates[low - 1]
        let b = coordinates[low]
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * fraction,
            longitude: a.longitude + (b.longitude - a.longitude) * fraction
        )
    }
}

struct DriveRoutePlannerView: View {
    let initialStart: CLLocationCoordinate2D?
    let initialDestination: CLLocationCoordinate2D?
    let onPrepared: (DriveRoutePlan, Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var startText = ""
    @State private var destinationText = ""
    @State private var stopTexts: [String] = []
    @State private var speedMPH = 30.0
    @State private var customSpeed = false
    @State private var isPreparing = false
    @State private var errorMessage: String?
    @StateObject private var suggestions = LocationSearchCompleter()
    @FocusState private var focusedField: RouteField?

    private enum RouteField: Hashable { case start, stop(Int), destination }

    private var canPrepare: Bool {
        (!startText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || initialStart != nil)
        && (!destinationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || initialDestination != nil)
        && !isPreparing
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Route") {
                    HStack {
                        Image(systemName: "circle.fill").foregroundStyle(.green)
                        TextField(initialStart == nil ? "Start place or address" : "Current location", text: $startText)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .start)
                    }
                    suggestionRows(for: .start)
                    ForEach(stopTexts.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "mappin.and.ellipse").foregroundStyle(.orange)
                            TextField("Stop \(index + 1) place or address", text: $stopTexts[index])
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .stop(index))
                            Button(role: .destructive) { stopTexts.remove(at: index) } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                        }
                        suggestionRows(for: .stop(index))
                    }
                    Button("Add Stop", systemImage: "plus.circle") { stopTexts.append("") }
                    HStack {
                        Image(systemName: "mappin.circle.fill").foregroundStyle(.red)
                        TextField(initialDestination == nil ? "Destination place or address" : "Selected map pin", text: $destinationText)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .destination)
                    }
                    suggestionRows(for: .destination)
                    Text("Leave Start blank to use your current location.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Speed") {
                    Toggle("Set my own speed", isOn: $customSpeed)
                    if customSpeed {
                        Slider(value: $speedMPH, in: 5...90, step: 1) {
                            Text("Speed")
                        }
                        Text("\(Int(speedMPH)) mph")
                            .font(.headline.monospacedDigit())
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        prepareRoute()
                    } label: {
                        HStack {
                            if isPreparing { ProgressView().padding(.trailing, 6) }
                            Text(isPreparing ? "Finding road route…" : "Preview Route")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!canPrepare)
                }
            }
            .navigationTitle("Plan a Drive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: focusedField) { _, _ in updateSuggestions() }
            .onChange(of: startText) { _, _ in updateSuggestions() }
            .onChange(of: destinationText) { _, _ in updateSuggestions() }
            .onChange(of: stopTexts) { _, _ in updateSuggestions() }
        }
    }

    @ViewBuilder
    private func suggestionRows(for field: RouteField) -> some View {
        if focusedField == field {
            ForEach(suggestions.results.prefix(4), id: \.self) { result in
                Button {
                    let name = [result.title, result.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
                    switch field {
                    case .start: startText = name
                    case .destination: destinationText = name
                    case .stop(let index): if stopTexts.indices.contains(index) { stopTexts[index] = name }
                    }
                    focusedField = nil
                    suggestions.update(query: "")
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title).foregroundStyle(.primary)
                        if !result.subtitle.isEmpty {
                            Text(result.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func updateSuggestions() {
        let query: String
        switch focusedField {
        case .start: query = startText
        case .destination: query = destinationText
        case .stop(let index): query = stopTexts.indices.contains(index) ? stopTexts[index] : ""
        case nil: query = ""
        }
        suggestions.update(query: coordinates(in: query) == nil ? query : "")
    }

    private func prepareRoute() {
        guard canPrepare else { return }
        isPreparing = true
        errorMessage = nil
        Task { @MainActor in
            do {
                let start = try await resolve(startText, fallback: initialStart, fallbackName: "Current location")
                let destination = try await resolve(destinationText, fallback: initialDestination, fallbackName: "Selected map pin")
                var places = [start]
                for stop in stopTexts where !stop.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    places.append(try await resolve(stop, fallback: nil, fallbackName: "Stop"))
                }
                places.append(destination)
                var routes: [MKRoute] = []
                for index in 1..<places.count {
                    let request = MKDirections.Request()
                    request.source = places[index - 1].item
                    request.destination = places[index].item
                    request.transportType = .automobile
                    request.requestsAlternateRoutes = false
                    let response = try await MKDirections(request: request).calculate()
                    guard let route = response.routes.first else { throw RouteError.noRoadRoute }
                    routes.append(route)
                }
                guard let plan = DriveRoutePlan(
                    routes: routes,
                    startName: start.name,
                    destinationName: destination.name,
                    stopNames: places.dropFirst().dropLast().map(\.name)
                ) else {
                    throw RouteError.noRoadRoute
                }
                onPrepared(plan, customSpeed ? speedMPH : 0)
                dismiss()
            } catch {
                errorMessage = "Could not find a driving route. Check both places and try again. \(error.localizedDescription)"
            }
            isPreparing = false
        }
    }

    private func resolve(
        _ text: String,
        fallback: CLLocationCoordinate2D?,
        fallbackName: String
    ) async throws -> (item: MKMapItem, name: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty, let fallback {
            return (MKMapItem(placemark: MKPlacemark(coordinate: fallback)), fallbackName)
        }
        if let coordinates = coordinates(in: query) {
            return (MKMapItem(placemark: MKPlacemark(coordinate: coordinates)), query)
        }
        guard !query.isEmpty else { throw RouteError.missingPlace }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else { throw RouteError.missingPlace }
        return (item, item.name ?? query)
    }

    private func coordinates(in text: String) -> CLLocationCoordinate2D? {
        let values = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard values.count == 2 else { return nil }
        let result = CLLocationCoordinate2D(latitude: values[0], longitude: values[1])
        return CLLocationCoordinate2DIsValid(result) ? result : nil
    }

    private enum RouteError: LocalizedError {
        case missingPlace
        case noRoadRoute

        var errorDescription: String? {
            switch self {
            case .missingPlace: "Enter a start and destination."
            case .noRoadRoute: "No drivable route was returned."
            }
        }
    }
}
