import SwiftUI
import CoreLocation

struct PointTeleportView: View {
    let onTeleport: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var latitude = ""
    @State private var longitude = ""

    private var point: CLLocationCoordinate2D? {
        guard let lat = Double(latitude.trimmingCharacters(in: .whitespacesAndNewlines)),
              let lon = Double(longitude.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let result = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        return CLLocationCoordinate2DIsValid(result) ? result : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Latitude (-90 to 90)", text: $latitude)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Longitude (-180 to 180)", text: $longitude)
                        .keyboardType(.numbersAndPunctuation)
                } header: {
                    Text("Exact point")
                } footer: {
                    Text("Enter decimal degrees. This sets one exact location until you tap Stop or Return to Real Location.")
                }
                Section {
                    Button("Teleport to Point") {
                        guard let point else { return }
                        onTeleport(point)
                        dismiss()
                    }
                    .disabled(point == nil)
                }
            }
            .navigationTitle("Point Teleport")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}
