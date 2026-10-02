import SwiftUI
import UIKit

/// Preparation guidance only. Connection readiness is checked by RootView.
struct SetupGuideView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "location.north.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.teal)
                        .accessibilityHidden(true)
                    Text("Your location lab.")
                        .font(.largeTitle.bold())
                    Text("Pick a place on your iPhone and test a simulated location, without keeping a computer connected.")
                        .foregroundStyle(.secondary)
                    Label("This device: iOS \(UIDevice.current.systemVersion)", systemImage: "iphone")
                        .font(.subheadline)
                    Text("Tested on iPhone 16 Pro with iOS 26.0. Results can vary with connectivity and background operation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    step("1", "Enable Developer Mode", "In Settings → Privacy & Security, enable Developer Mode and follow the restart prompt. Trust the computer when connecting by USB for initial setup.")
                    step("2", "Start LocalDevVPN", "Install and enable the local connection helper. Join a Wi-Fi network for the first connection test.")
                    Link("Get LocalDevVPN", destination: URL(string: "https://apps.apple.com/us/app/localdevvpn/id6755608044")!)
                    step("3", "Import this phone’s pairing file", "Continue to the connection screen and import the pairing file created for this iPhone. Keep this file private; do not upload it to a public repository.")
                    Link("Pairing instructions", destination: URL(string: "https://github.com/StikDebug/StikDebug-Guide/blob/main/pairing_file.md")!)
                    step("4", "Check the connection, then choose a place", "Wait for the connection and developer image to be ready. Search or drop a pin, start simulation, and verify the result in Apple Maps. Use Return to Real Location when finished.")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test before relying on it").font(.headline)
                        Text("The location may reset if iOS suspends the app or the connection drops. Test unplugging, switching apps, locking the screen, and leaving Wi-Fi separately. Background operation can use additional battery.")
                        Text("This prototype does not renew its own signing. Refresh with your signing tool before the installation expires.")
                    }
                    .font(.subheadline)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Built on open source").font(.headline)
                        Text("ALoco is a derivative of TLocation and StikDebug by Stephen Bove and contributors, using idevice by jkcoxson. AGPL-3.0. It is not affiliated with Vanish.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Link("TLocation source", destination: URL(string: "https://github.com/truongkma/t-location")!)
                        Link("StikDebug source", destination: URL(string: "https://github.com/StikDebug/StikDebug")!)
                    }
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: onContinue) {
                    Text("Continue to Connection")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .padding()
                .background(.regularMaterial)
            }
            .navigationTitle("ALoco")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func step(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline.monospacedDigit())
                .frame(width: 32, height: 32)
                .background(.teal.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
