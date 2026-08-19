import SwiftUI

struct TodayView: View {
    @Bindable var store: DemoStore
    var referenceDate: Date = .now
    @State private var isCapturePresented = false

    private var todayItems: [PlanItem] {
        store.planItems
            .filter { item in
                guard let date = item.referenceDate else { return false }
                return Calendar.autoupdatingCurrent.isDate(date, inSameDayAs: referenceDate)
            }
            .sorted { ($0.referenceDate ?? .distantFuture) < ($1.referenceDate ?? .distantFuture) }
    }

    private var attentionItems: [PlanItem] {
        store.planItems
            .filter { ($0.kind == .deadline || $0.kind == .payment) && !$0.isCompleted }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
            .prefix(3).map { $0 }
    }

    private var pendingReviews: [InboxSource] {
        store.inboxItems.filter { $0.status == .review || $0.status == .partial }.sorted { $0.createdAt > $1.createdAt }
    }

    private var tomorrowPreparationItems: [PlanItem] {
        guard let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: referenceDate) else { return [] }
        return store.planItems
            .filter { !$0.isCompleted && [.deadline, .preparation, .task].contains($0.kind) }
            .filter { item in
                guard let date = item.referenceDate else { return false }
                return Calendar.autoupdatingCurrent.isDate(date, inSameDayAs: tomorrow)
            }
            .sorted { ($0.referenceDate ?? .distantFuture) < ($1.referenceDate ?? .distantFuture) }
    }

    private var scheduleConflict: (PlanItem, PlanItem)? {
        let scheduled = todayItems.filter { $0.startsAt != nil && $0.endsAt != nil }
        for i in scheduled.indices {
            for j in scheduled.indices where j > i {
                let a = scheduled[i], b = scheduled[j]
                guard let asd = a.startsAt, let aed = a.endsAt, let bsd = b.startsAt, let bed = b.endsAt else { continue }
                if asd < bed && bsd < aed && !a.memberIDs.isDisjoint(with: b.memberIDs) { return (a, b) }
            }
        }
        return nil
    }

    private var greeting: String {
        switch Calendar.autoupdatingCurrent.component(.hour, from: referenceDate) {
        case 5..<12: "Guten Morgen"
        case 12..<18: "Guten Tag"
        default: "Guten Abend"
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header
                if !pendingReviews.isEmpty || !attentionItems.isEmpty || scheduleConflict != nil { attentionSection }
                familyBrief
                timeline
                if !tomorrowPreparationItems.isEmpty { prepareSection }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Heute")
        .refreshable { await store.refreshHosted() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCapturePresented = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Etwas hinzufügen")
            }
        }
        .sheet(isPresented: $isCapturePresented) { CaptureView(store: store) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.longDate(referenceDate)).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
            Text(greeting).font(.largeTitle.bold())
        }
        .padding(.top, 8)
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Braucht Aufmerksamkeit")
            VStack(spacing: 0) {
                ForEach(pendingReviews.prefix(2)) { source in
                    Button { store.openReviewV1(sourceID: source.id) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "tray.full.fill").foregroundStyle(.indigo).frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                                Text("\(source.proposalCount) Vorschläge prüfen").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .padding(14)
                    }
                    .buttonStyle(.plain)
                    Divider().padding(.leading, 54)
                }

                if let conflict = scheduleConflict {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark").foregroundStyle(.orange).frame(width: 32)
                        VStack(alignment: .leading) {
                            Text("Terminüberschneidung").font(.subheadline.weight(.semibold))
                            Text("\(conflict.0.title) · \(conflict.1.title)").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(14)
                    if !attentionItems.isEmpty { Divider().padding(.leading, 54) }
                }

                ForEach(attentionItems) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.kind.systemImage).foregroundStyle(.orange).frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title).font(.subheadline.weight(.semibold))
                            if let due = item.dueAt { Text(due.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        completionButton(item)
                    }
                    .padding(14)
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private var familyBrief: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Familienüberblick", systemImage: "sparkles").font(.headline).foregroundStyle(.primary)
            Text(briefText).font(.body)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
    }

    private var briefText: String {
        if !pendingReviews.isEmpty { return "\(pendingReviews.count) Import\(pendingReviews.count == 1 ? "" : "e") warten auf eure Freigabe." }
        if scheduleConflict != nil { return "Heute überschneiden sich bestätigte Termine. Prüft kurz die Zuständigkeit." }
        if let first = attentionItems.first { return "Als Nächstes braucht „\(first.title)“ Aufmerksamkeit." }
        if todayItems.isEmpty { return "Heute ist alles ruhig. Neue Infos kannst du per Foto, Datei, Text oder Sprache hinzufügen." }
        return "Heute stehen \(todayItems.count) Einträge im Familienplan."
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Heute", trailing: referenceDate.formatted(.dateTime.day().month()))
            if todayItems.isEmpty {
                ContentUnavailableView {
                    Label("Heute ist alles ruhig", systemImage: "checkmark.circle")
                } description: { Text("Neue Infos kannst du direkt hinzufügen.") }
                actions: { Button("Etwas hinzufügen") { isCapturePresented = true }.buttonStyle(.borderedProminent) }
            } else {
                VStack(spacing: 0) {
                    ForEach(todayItems) { item in
                        AgendaRow(item: item, members: store.members, showsCompletion: item.kind != .event, onToggleCompletion: { store.toggleCompletion(item.id) })
                            .padding(.vertical, 8)
                        if item.id != todayItems.last?.id { Divider().padding(.leading, 74) }
                    }
                }
                .padding(.horizontal, 14)
                .background(.background, in: RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    private var prepareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Für morgen vorbereiten")
            VStack(spacing: 0) {
                ForEach(tomorrowPreparationItems) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.kind.systemImage).foregroundStyle(item.kind.tint).frame(width: 34)
                        Text(item.title).font(.subheadline.weight(.semibold))
                        Spacer()
                        completionButton(item)
                    }
                    .padding(14)
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func completionButton(_ item: PlanItem) -> some View {
        Button { store.toggleCompletion(item.id) } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isCompleted ? .green : .secondary)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
    }

    private static func longDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "de_DE"); formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }

    static func previewDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var c = DateComponents(); c.calendar = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/Berlin")
        c.year = year; c.month = month; c.day = day; c.hour = hour; c.minute = minute
        return c.date ?? .now
    }
}

#Preview { NavigationStack { TodayView(store: DemoStore()) } }
