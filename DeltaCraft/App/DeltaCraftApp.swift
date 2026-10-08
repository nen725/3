import SwiftUI

@main
struct DeltaCraftApp: App {
    @State private var store = AppStore.shared

    init() {
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .task {
                    await NotificationManager.shared.requestAuthorization()
                }
        }
    }
}
