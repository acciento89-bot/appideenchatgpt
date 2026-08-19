import SwiftUI

struct RootView: View {
    @Bindable var store: DemoStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedSection: AppSection = .today
    @State private var isShowingSettings = false
    @State private var appLock = FamilyAppLock()

    private enum AppSection: String, CaseIterable, Identifiable, Hashable {
        case today, inbox, plan, family
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

    private var sidebarSelection: Binding<AppSection?> {
        Binding(get: { selectedSection }, set: { if let $0 { selectedSection = $0 } })
    }

    private var showsRepositoryError: Binding<Bool> {
        Binding(
            get: { store.repositoryErrorMessage != nil },
            set: { if !$0 { store.repositoryErrorMessage = nil } }
        )
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular { tabletShell }
            else { phoneShell }
        }
        .sheet(isPresented: $store.isImportReviewPresented) {
            NavigationStack { ImportReviewView(store: store) }
        }
        .sheet(isPresented: $isShowingSettings) {
            FamilySettingsView(store: store, appLock: appLock)
        }
        .alert("Aktion fehlgeschlagen", isPresented: showsRepositoryError) {
            Button("OK", role: .cancel) { store.repositoryErrorMessage = nil }
        } message: {
            Text(store.repositoryErrorMessage ?? "Unbekannter Fehler")
        }
    }

    private var phoneShell: some View {
        TabView(selection: $selectedSection) {
            NavigationStack { TodayView(store: store) }
                .tag(AppSection.today)
                .tabItem { Label(AppSection.today.title, systemImage: AppSection.today.systemImage) }

            NavigationStack { InboxView(store: store) }
                .tag(AppSection.inbox)
                .tabItem { Label(AppSection.inbox.title, systemImage: AppSection.inbox.systemImage) }

            NavigationStack { PlanView(store: store) }
                .tag(AppSection.plan)
                .tabItem { Label(AppSection.plan.title, systemImage: AppSection.plan.systemImage) }

            NavigationStack {
                FamilyView(store: store)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { isShowingSettings = true } label: { Image(systemName: "gearshape") }
                                .accessibilityLabel("Einstellungen")
                        }
                    }
            }
            .tag(AppSection.family)
            .tabItem { Label(AppSection.family.title, systemImage: AppSection.family.systemImage) }
        }
    }

    private var tabletShell: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: sidebarSelection) { section in
                Label(section.title, systemImage: section.systemImage).tag(section)
            }
            .navigationTitle(store.household?.name ?? "Familie")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            NavigationStack {
                destination(for: selectedSection)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { isShowingSettings = true } label: { Image(systemName: "gearshape") }
                                .accessibilityLabel("Einstellungen")
                        }
                    }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .today: TodayView(store: store)
        case .inbox: InboxView(store: store)
        case .plan: PlanView(store: store)
        case .family: FamilyView(store: store)
        }
    }
}

#Preview("iPhone") { RootView(store: DemoStore()) }
#Preview("iPad") { RootView(store: DemoStore()).environment(\.horizontalSizeClass, .regular) }
