import AppKit
import Combine
import CoreLocation
import MapKit
import SwiftUI

private let alocoBlue = Color(red: 0.18, green: 0.73, blue: 0.90)
private let glassInk = Color(red: 0.10, green: 0.17, blue: 0.21)

@MainActor
final class RouteStudio: ObservableObject {
    @Published var start = "Mercer Island, WA"
    @Published var destination = "Mercer Island United Methodist Church"
    @Published var route: MKRoute?
    @Published var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.583, longitude: -122.245),
            span: MKCoordinateSpan(latitudeDelta: 0.055, longitudeDelta: 0.075)
        )
    )
    @Published var speed = 30.0
    @Published var fraction = 0.0
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var message: String?
    @Published var pointSearch = "Starbucks, Mercer Island"
    @Published var pointCoordinate: CLLocationCoordinate2D?
    @Published var pointOrigin: CLLocationCoordinate2D?
    @Published var pointProgress = 0.0
    @Published var pointStatus: String?

    private var startedAt: Date?
    private var path: [CLLocationCoordinate2D] = []
    private var cumulative: [Double] = []
    private var pointAnimationID = UUID()

    var movingPoint: CLLocationCoordinate2D? {
        guard let pointOrigin, let pointCoordinate else { return nil }
        return CLLocationCoordinate2D(
            latitude: pointOrigin.latitude + (pointCoordinate.latitude - pointOrigin.latitude) * pointProgress,
            longitude: pointOrigin.longitude + (pointCoordinate.longitude - pointOrigin.longitude) * pointProgress
        )
    }

    func previewTeleport() async {
        let query = pointSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { message = "Enter a place or address."; return }
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            let target = try await search(query).placemark.coordinate
            let origin = pointCoordinate ?? CLLocationCoordinate2D(latitude: 47.583, longitude: -122.245)
            pointOrigin = origin
            pointCoordinate = target
            pointProgress = 0
            pointStatus = "Moving your location"
            let id = UUID()
            pointAnimationID = id
            camera = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: (origin.latitude + target.latitude) / 2,
                                               longitude: (origin.longitude + target.longitude) / 2),
                span: MKCoordinateSpan(latitudeDelta: max(abs(origin.latitude - target.latitude) * 1.8, 0.012),
                                       longitudeDelta: max(abs(origin.longitude - target.longitude) * 1.8, 0.012))
            ))
            withAnimation(.easeInOut(duration: 2.0)) { pointProgress = 1 }
            try? await Task.sleep(for: .seconds(2.1))
            guard pointAnimationID == id else { return }
            pointStatus = "Location preview complete"
            withAnimation(.smooth(duration: 0.6)) {
                camera = .region(MKCoordinateRegion(center: target,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.016)))
            }
        } catch {
            message = "We couldn't find that place. Try an address."
        }
    }

    var distanceMiles: Double { (route?.distance ?? 0) / 1609.344 }
    var drivenMiles: Double { distanceMiles * fraction }
    var etaMinutes: Int {
        guard let route else { return 0 }
        let seconds = route.distance * (1 - fraction) / max(speed * 0.44704, 0.1)
        return Int(ceil(seconds / 60))
    }
    var carCoordinate: CLLocationCoordinate2D? {
        guard let route, path.count > 1 else { return nil }
        let target = route.distance * fraction
        let last = cumulative.last ?? 0
        let distance = min(max(target, 0), last)
        guard distance > 0 else { return path[0] }
        guard distance < last else { return path[path.count - 1] }
        let index = cumulative.firstIndex(where: { $0 >= distance }) ?? cumulative.count - 1
        let preceding = max(index - 1, 0)
        let section = max(cumulative[index] - cumulative[preceding], 0.001)
        let blend = (distance - cumulative[preceding]) / section
        let a = path[preceding]
        let b = path[index]
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * blend,
            longitude: a.longitude + (b.longitude - a.longitude) * blend
        )
    }

    func plan() async {
        let a = start.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !a.isEmpty, !b.isEmpty else {
            message = "Add a start and destination."
            return
        }
        stop()
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            let first = try await search(a)
            let last = try await search(b)
            let request = MKDirections.Request()
            request.source = first
            request.destination = last
            request.transportType = .automobile
            let response = try await MKDirections(request: request).calculate()
            guard let candidate = response.routes.first else {
                throw RouteError.noRoute
            }
            route = candidate
            loadPath(candidate.polyline)
            fraction = 0
            let bounds = candidate.polyline.boundingMapRect
            let padX = max(bounds.width * 0.20, 5_000)
            let padY = max(bounds.height * 0.28, 5_000)
            camera = .rect(MKMapRect(
                x: bounds.minX - padX,
                y: bounds.minY - padY,
                width: bounds.width + padX * 2,
                height: bounds.height + padY * 2
            ))
        } catch {
            route = nil
            message = "We couldn't find that drive. Check the places and try again."
        }
    }

    func play() {
        guard route != nil else { return }
        if fraction >= 1 { fraction = 0 }
        let elapsed = (route?.distance ?? 0) * fraction / max(speed * 0.44704, 0.1)
        startedAt = Date().addingTimeInterval(-elapsed)
        isPlaying = true
    }

    func stop() {
        isPlaying = false
        startedAt = nil
    }

    func reset() {
        stop()
        fraction = 0
    }

    func tick() {
        guard isPlaying, let route, let startedAt else { return }
        let covered = max(0, Date().timeIntervalSince(startedAt)) * speed * 0.44704
        fraction = min(1, covered / max(route.distance, 1))
        if fraction >= 1 { stop() }
    }

    private func search(_ text: String) async throws -> MKMapItem {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.583, longitude: -122.245),
            span: MKCoordinateSpan(latitudeDelta: 0.4, longitudeDelta: 0.4)
        )
        guard let item = try await MKLocalSearch(request: request).start().mapItems.first else {
            throw RouteError.noPlace
        }
        return item
    }

    private func loadPath(_ polyline: MKPolyline) {
        path = Array(repeating: CLLocationCoordinate2D(), count: polyline.pointCount)
        polyline.getCoordinates(&path, range: NSRange(location: 0, length: polyline.pointCount))
        cumulative = [0]
        for index in 1..<path.count {
            let first = CLLocation(latitude: path[index - 1].latitude, longitude: path[index - 1].longitude)
            let second = CLLocation(latitude: path[index].latitude, longitude: path[index].longitude)
            cumulative.append(cumulative[index - 1] + second.distance(from: first))
        }
    }

    private enum RouteError: Error { case noPlace, noRoute }
}

struct ALocoMacView: View {
    @StateObject private var studio = RouteStudio()
    @State private var mode: Mode = .routes
    @State private var showingAbout = false
    private let timer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    private enum Mode: String, CaseIterable { case point = "Point", routes = "Routes" }

    var body: some View {
        ZStack(alignment: .leading) {
            mapArea
            sidebar
                .padding(20)
        }
        .frame(minWidth: 1050, minHeight: 680)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    showingAbout = true
                } label: {
                    Label("About ALoco", systemImage: "info.circle")
                }
                .help("About this Mac preview")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await studio.plan() }
                } label: {
                    Label("Find Route", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .alert("ALoco for Mac", isPresented: $showingAbout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This is a route preview on your Mac. It does not connect to or change your iPhone's location yet.")
        }
        .onReceive(timer) { _ in studio.tick() }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                logo.frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ALoco").font(.system(size: 21, weight: .semibold, design: .rounded))
                    Text("Route studio").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 25)
            .padding(.bottom, 25)

            VStack(alignment: .leading, spacing: 8) {
                Text(mode == .routes ? "ROUTE" : "POINT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(alocoBlue)
                Text(mode == .routes ? "Where to?" : "Choose a place")
                    .font(.system(size: 29, weight: .semibold, design: .rounded))
                    .padding(.bottom, 14)

                if mode == .routes {
                    routeInput(icon: "circle.fill", color: .green, title: "Start", text: $studio.start)
                    Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 1).padding(.leading, 43)
                    routeInput(icon: "mappin.circle.fill", color: .red, title: "Destination", text: $studio.destination)
                } else {
                    routeInput(icon: "mappin.circle.fill", color: alocoBlue, title: "Location", text: $studio.pointSearch)
                }
            }
            .padding(18)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.11), lineWidth: 1))
            .padding(.horizontal, 18)

            if mode == .routes { VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Speed").font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("\(Int(studio.speed)) mph")
                        .font(.system(size: 14, weight: .semibold, design: .rounded).monospacedDigit())
                        .foregroundStyle(alocoBlue)
                }
                Slider(value: $studio.speed, in: 5...90, step: 5)
                    .tint(alocoBlue)
                    .onChange(of: studio.speed) { _, _ in if studio.isPlaying { studio.play() } }
                HStack {
                    Text("5 mph")
                    Spacer()
                    Text("90 mph")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 28)
            .padding(.top, 30) }

            if mode == .point, let pointStatus = studio.pointStatus {
                Label(pointStatus, systemImage: "location.north.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(alocoBlue)
                    .padding(.horizontal, 28)
                    .padding(.top, 23)
            }

            if let message = studio.message {
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
            }

            Spacer(minLength: 15)

            VStack(spacing: 10) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.bottom, 7)

                Button {
                    Task {
                        if mode == .routes { await studio.plan() }
                        else { await studio.previewTeleport() }
                    }
                } label: {
                    HStack {
                        Spacer()
                        if studio.isLoading { ProgressView().controlSize(.small) }
                        Text(studio.isLoading ? "Finding location…" : mode == .routes ? "Find route" : "Preview teleport")
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                    }
                    .frame(height: 42)
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(colors: [alocoBlue, Color(red: 0.09, green: 0.58, blue: 0.78)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.26), lineWidth: 1))
                    .shadow(color: alocoBlue.opacity(0.24), radius: 12, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(studio.isLoading)
                .keyboardShortcut(.return, modifiers: .command)

                HStack(spacing: 6) {
                    Image(systemName: "iphone")
                    Text("Mac route preview")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 25)
        }
        .frame(width: 355)
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay {
                    RoundedRectangle(cornerRadius: 27, style: .continuous)
                        .fill(glassInk.opacity(0.69))
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 27, style: .continuous).stroke(.white.opacity(0.26), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 30, x: 7, y: 12)
        .environment(\.colorScheme, .dark)
    }

    private func routeInput(icon: String, color: Color, title: String, text: Binding<String>) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                TextField("Place or address", text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium))
                    .onSubmit {
                        Task {
                            if mode == .routes { await studio.plan() }
                            else { await studio.previewTeleport() }
                        }
                    }
            }
        }
        .padding(.vertical, 9)
    }

    private var mapArea: some View {
        ZStack(alignment: .top) {
            Map(position: $studio.camera) {
                if mode == .point, let destination = studio.pointCoordinate {
                    if let origin = studio.pointOrigin, studio.pointStatus != nil {
                        MapPolyline(coordinates: [origin, destination])
                            .stroke(alocoBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [5, 9]))
                    }
                    Marker("Location", systemImage: "mappin", coordinate: destination)
                        .tint(alocoBlue)
                    if let movingPoint = studio.movingPoint, studio.pointStatus != nil {
                        Annotation("", coordinate: movingPoint) {
                            Image(systemName: "location.north.fill")
                                .foregroundStyle(.white)
                                .padding(11)
                                .background(alocoBlue, in: Circle())
                                .shadow(color: alocoBlue.opacity(0.65), radius: 13)
                        }
                    }
                }
                if mode == .routes, let route = studio.route {
                    MapPolyline(route.polyline)
                        .stroke(alocoBlue, style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [3, 9]))
                    Marker("Start", systemImage: "circle.fill", coordinate: route.polyline.coordinate)
                        .tint(.green)
                    if let destination = routeDestination(route) {
                        Marker("Destination", systemImage: "flag.fill", coordinate: destination)
                            .tint(.red)
                    }
                    if let car = studio.carCoordinate {
                        Annotation("", coordinate: car, anchor: .center) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(alocoBlue, in: Circle())
                                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .environment(\.colorScheme, .light)
            .mapControls {
                MapCompass()
                MapScaleView()
            }

            HStack {
                Spacer()
                Label("Mac preview", systemImage: "macbook")
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.7), lineWidth: 1))
            }
            .padding(22)

            if mode == .routes && studio.route != nil {
                HStack {
                    Spacer()
                    progressCard.frame(maxWidth: 585)
                }
                .padding(24)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(studio.fraction >= 1 ? "Preview complete" : studio.isPlaying ? "Previewing drive" : "Your route")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("A road-following preview on this Mac")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if studio.isPlaying {
                    Button("Stop preview", systemImage: "stop.fill") { studio.stop() }
                        .buttonStyle(.bordered)
                } else {
                    Button(studio.fraction >= 1 ? "Replay" : "Preview drive", systemImage: "play.fill") { studio.play() }
                        .buttonStyle(.borderedProminent)
                        .tint(alocoBlue)
                }
            }
            ProgressView(value: studio.fraction)
                .tint(alocoBlue)
            HStack(spacing: 32) {
                statistic("DRIVEN", value: String(format: "%.2f mi", studio.drivenMiles))
                statistic("SPEED", value: "\(Int(studio.speed)) mph")
                statistic("ETA", value: "\(studio.etaMinutes) min")
                Spacer()
                Text(String(format: "%.2f mi total", studio.distanceMiles))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: 610)
        .background {
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(glassInk.opacity(0.68)))
        }
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.24), radius: 24, y: 10)
        .environment(\.colorScheme, .dark)
    }

    private func statistic(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.system(size: 10, weight: .semibold)).tracking(0.6).foregroundStyle(.secondary)
            Text(value).font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
        }
    }

    private var logo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(alocoBlue.opacity(0.1))
            if let path = Bundle.main.path(forResource: "LaunchLogo", ofType: "png"),
               let image = NSImage(contentsOfFile: path) {
                Image(nsImage: image).resizable().scaledToFit().padding(5)
            } else {
                Image(systemName: "location.north.fill").foregroundStyle(alocoBlue)
            }
        }
    }

    private func routeDestination(_ route: MKRoute) -> CLLocationCoordinate2D? {
        let line = route.polyline
        guard line.pointCount > 0 else { return nil }
        var coordinate = CLLocationCoordinate2D()
        line.getCoordinates(&coordinate, range: NSRange(location: line.pointCount - 1, length: 1))
        return coordinate
    }
}

@main
struct ALocoMacApp: App {
    var body: some Scene {
        WindowGroup("ALoco") { ALocoMacView() }
            .windowStyle(.titleBar)
    }
}
