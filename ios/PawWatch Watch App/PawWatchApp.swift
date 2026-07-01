import SwiftUI

@main
struct PawWatchApp: App {
    @StateObject private var health = HealthModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(health)
                .onAppear { health.start() }
        }
    }
}
