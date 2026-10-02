import SwiftUI
import MapKit

@main
struct ALOCOPreviewApp: App {
    var body: some Scene {
        WindowGroup { PreviewRootView() }
    }
}

private struct PreviewRootView: View {
    @State private var showingGuide = true
    @State private var searchText = ""
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
    )
    @State private var selected = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var simulated = false
    @State private var searchMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showingGuide {
                    guide
                } else {
                    mapScreen
                }
            }
            .navigationTitle("ALOCO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showingGuide {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Guide", systemImage: "questionmark.circle") { showingGuide = true }
                    }
                }
            }
        }
    }

    private var guide: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Image(systemName: "location.north.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.teal)
                Text("Your location lab.").font(.largeTitle.bold())
                Text("Pick a place on your iPhone and test a simulated location without keeping a computer connected.")
                    .foregroundStyle(.secondary)
                Label("Simulator interface preview", systemImage: "iphone.gen3")
                    .font(.subheadline.bold())
                Text("This preview lets us inspect the map and setup screens. It does not change the simulator's system location. The physical iPhone build contains the real location engine.")
                    .font(.subheadline)
                    .padding()
                    .background(.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                step("1", "Enable Developer Mode", "Enable it on the iPhone and finish the restart prompt.")
                step("2", "Start LocalDevVPN", "Use the local connection helper on your iPhone.")
                step("3", "Import your pairing file", "Pairing credentials belong only on your own device.")
                step("4", "Pick a place", "Check that the connection is ready, then test in Apple Maps.")
                Button("Open Map Preview") { showingGuide = false }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .frame(maxWidth: .infinity)
                Text("Based on TLocation and StikDebug (AGPL-3.0), with idevice. Unaffiliated with Vanish.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }

    private var mapScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Search for a place", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit { Task { await search() } }
                Button("Search") { Task { await search() } }
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()

            MapReader { proxy in
                Map(position: $position) {
                    Annotation("Selected", coordinate: selected) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.teal)
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .onTapGesture { point in
                    if let coordinate = proxy.convert(point, from: .local) { selected = coordinate }
                }
            }

            VStack(spacing: 12) {
                if let searchMessage {
                    Text(searchMessage).font(.caption).foregroundStyle(.orange)
                }
                Text(String(format: "%.5f, %.5f", selected.latitude, selected.longitude))
                    .font(.subheadline.monospacedDigit())
                Text(simulated ? "Preview marker active" : "Tap the map to select a place")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(simulated ? "Return to Real Location" : "Preview Location") {
                    simulated.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .frame(maxWidth: .infinity)
                Text("Simulator demo only — no system location change")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
        }
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.headline.monospacedDigit())
                .frame(width: 32, height: 32)
                .background(.teal.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    @MainActor
    private func search() async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        do {
            guard let item = try await MKLocalSearch(request: request).start().mapItems.first else {
                searchMessage = "No places found."
                return
            }
            selected = item.placemark.coordinate
            position = .region(MKCoordinateRegion(center: selected, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)))
            searchMessage = nil
        } catch {
            searchMessage = "Search unavailable. Check your network connection."
        }
    }
}
