import SwiftUI

struct LaunchSplashView: View {
    @State private var outlineProgress = 0.0
    @State private var nameVisible = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 22) {
                IsraelOutline()
                    .trim(from: 0, to: outlineProgress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 100, height: 205)
                Text("ALoco")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .opacity(nameVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.35)) { outlineProgress = 1 }
            withAnimation(.easeIn(duration: 0.45).delay(0.9)) { nameVisible = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ALoco opening")
    }
}
