import SwiftUI

struct RootView: View {
    @Bindable var store: DemoStore

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(store: store)
            }
            .tabItem {
                Label("Heute", systemImage: "house.fill")
            }

            NavigationStack {
                InboxView(store: store)
            }
            .tabItem {
                Label("Inbox", systemImage: "tray.fill")
            }

            NavigationStack {
                PlanView(store: store)
            }
            .tabItem {
                Label("Plan", systemImage: "calendar")
            }

            NavigationStack {
                FamilyView(store: store)
            }
            .tabItem {
                Label("Familie", systemImage: "person.3.fill")
            }
        }
        .sheet(isPresented: $store.isImportReviewPresented) {
            NavigationStack {
                ImportReviewView(store: store)
            }
        }
    }
}
