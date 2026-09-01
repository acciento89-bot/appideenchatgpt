import SwiftUI

@main
struct RapportAIApp: App {
    @StateObject private var store = RapportStore()
    @StateObject private var usage = UsageMeter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(usage)
                .preferredColorScheme(.dark)
        }
    }
}

