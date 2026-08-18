import SwiftUI

struct RootView: View {
    @Bindable var store: DemoStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection: AppSection = .today

    private enum AppSection: String, CaseIterable, Identifiable, Hashable {
        case today
        case inbox
        case plan
        case family

        var id: Self { self }

        var title: String {
            switch self {
            case .today: "Heute"
            case .inbox: "Inbox"
            case .plan: "Plan"
            case .family: "Familie"
            }
        }

        var systemImage: String {
            switch self {
            case .today: "house.fill"
            case .inbox: "tray.fill"
            case .plan: "calendar"
            case .family: "person.3.fill"
            }
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                tabletShell
            } else {
                phoneShell
            }
        }
        .sheet(isPresented: $store.isImportReviewPresented) {
            NavigationStack {
                ImportReviewView(store: store)
            }
        }
    }

    private var phoneShell: some View {
        TabView(selection: $selectedSection) {
            NavigationStack {
                TodayView(store: store)
            }
            .tag(AppSection.today)
            .tabItem {
                Label(AppSection.today.title, systemImage: AppSection.today.systemImage)
            }

            NavigationStack {
                InboxView(store: store)
            }
            .tag(AppSection.inbox)
            .tabItem {
                Label(AppSection.inbox.title, systemImage: AppSection.inbox.systemImage)
            }

            NavigationStack {
                PlanView(store: store)
            }
            .tag(AppSection.plan)
            .tabItem {
                Label(AppSection.plan.title, systemImage: AppSection.plan.systemImage)
            }

            NavigationStack {
                FamilyView(store: store)
            }
            .tag(AppSection.family)
            .tabItem {
                Label(AppSection.family.title, systemImage: AppSection.family.systemImage)
            }
        }
    }

    private var tabletShell: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Familie Berger")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            NavigationStack {
                destination(for: selectedSection)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .today:
            TodayView(store: store)
        case .inbox:
            InboxView(store: store)
        case .plan:
            PlanView(store: store)
        case .family:
            FamilyView(store: store)
        }
    }
}

#Preview("iPhone") {
    RootView(store: DemoStore())
}

#Preview("iPad") {
    RootView(store: DemoStore())
        .previewDevice("iPad Pro 11-inch (M4)")
}
