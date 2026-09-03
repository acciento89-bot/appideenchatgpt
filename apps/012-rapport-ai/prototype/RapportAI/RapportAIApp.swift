import SwiftUI

@main
struct RapportAIApp: App {
    @StateObject private var store = RapportStore()
    @StateObject private var usage = UsageMeter()
    @StateObject private var profile = CompanyProfileStore()
    @StateObject private var entitlements = EntitlementStore()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environmentObject(store)
                .environmentObject(usage)
                .environmentObject(profile)
                .environmentObject(entitlements)
                .preferredColorScheme(.dark)
        }
    }
}

private struct AppEntryView: View {
    @AppStorage("rapport.onboarding.completed") private var onboardingCompleted = false

    var body: some View {
        if onboardingCompleted {
            RootView()
        } else {
            OnboardingView(isPresented: Binding(
                get: { !onboardingCompleted },
                set: { onboardingCompleted = !$0 }
            ))
        }
    }
}
