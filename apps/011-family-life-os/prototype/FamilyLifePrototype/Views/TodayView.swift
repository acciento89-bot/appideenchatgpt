import SwiftUI

struct TodayView: View {
    @Bindable var store: DemoStore

    private var todayItems: [PlanItem] {
        store.planItems
            .filter { item in
                guard let date = item.startsAt ?? item.dueAt else { return false }
                return Self.isFixtureToday(date)
            }
            .sorted { ($0.startsAt ?? $0.dueAt ?? .distantFuture) < ($1.startsAt ?? $1.dueAt ?? .distantFuture) }
    }

    private var attentionItems: [PlanItem] {
        store.planItems
            .filter { $0.kind == .deadline || $0.kind == .payment }
            .filter { !$0.isCompleted }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .prefix(2)
            .map { $0 }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                if !attentionItems.isEmpty {
                    attentionSection
                }

                familyBrief

                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Heute", trailing: "18. August")

                    if todayItems.isEmpty {
                        ContentUnavailableView {
                            Label("Heute ist alles ruhig", systemImage: "checkmark.circle")
                        } description: {
                            Text("Neue Infos kannst du direkt über die Inbox hinzufügen.")
                        } actions: {
                            Button("Etwas hinzufügen") {
                                store.openSignatureReview()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ForEach(todayItems) { item in
                            AgendaRow(
                                item: item,
                                members: store.members,
                                showsCompletion: item.kind == .task,
                                onToggleCompletion: { store.toggleCompletion(item.id) }
                            )
                            if item.id != todayItems.last?.id {
                                Divider().padding(.leading, 74)
                            }
                        }
                    }
                }

                prepareSection
            }
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Heute")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.openSignatureReview()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Etwas hinzufügen")
                .accessibilityHint("Öffnet einen Beispielimport zum Prüfen")
                .accessibilityIdentifier("today-add")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dienstag, 18. August")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Guten Abend")
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Braucht Aufmerksamkeit", trailing: "\(attentionItems.count)")

            VStack(spacing: 0) {
                ForEach(attentionItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.kind.systemImage)
                            .foregroundStyle(.orange)
                            .frame(width: 28, height: 28)
                            .background(.orange.opacity(0.12), in: Circle())
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            if let due = item.dueAt {
                                Text(due, format: .dateTime.weekday(.wide).day().month())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .accessibilityElement(children: .combine)

                    if item.id != attentionItems.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityIdentifier("today-attention")
    }

    private var familyBrief: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.indigo)
                    .accessibilityHidden(true)
                Text("Familienüberblick")
                    .font(.headline)
            }

            Text("Ab 15:30 wird es voller: Lina hat Zahnarzt, danach muss Ben vom Training abgeholt werden. Für morgen ist noch die Einverständniserklärung offen.")
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("today-brief")
    }

    private var prepareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Für morgen vorbereiten")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.purple)
                    .frame(width: 34, height: 34)
                    .background(.purple.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Einverständniserklärung unterschreiben")
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Lina · morgen fällig")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private static func isFixtureToday(_ date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return components.year == 2026 && components.month == 8 && components.day == 18
    }
}

#Preview("Heute – Light") {
    NavigationStack {
        TodayView(store: DemoStore())
    }
}

#Preview("Heute – Dark") {
    NavigationStack {
        TodayView(store: DemoStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("Heute – Accessibility") {
    NavigationStack {
        TodayView(store: DemoStore())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
