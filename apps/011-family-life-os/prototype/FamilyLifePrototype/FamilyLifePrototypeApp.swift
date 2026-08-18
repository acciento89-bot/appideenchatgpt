import SwiftUI

@main
struct FamilyLifePrototypeApp: App {
    @State private var store = DemoStore()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
        }
    }
}
