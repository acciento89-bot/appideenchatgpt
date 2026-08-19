import SwiftUI

struct TodayView: View {
    @Bindable var store: DemoStore
    var referenceDate: Date = .now

    private var todayItems: [PlanItem] {
        store.planItems
            .filter { item in
                guard let date = item.startsAt ?? item.dueAt else { return false }
                return Calendar.autoupdatingCurrent.isDate(date, inSameDayAs: referenceDate)
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

    private var tomorrowPreparationItems: [PlanItem] {
        guard let tomorrow = Calendar.autoupdatingCurrent.date(byAdding: .day, value: 1, to: referenceDate) else {
            return []
        }

        return store.planItems
            .filter { !$0.isCompleted }
            .filter { $0.kind == .deadline || $0.kind == .preparation || $0.kind == .task }
            .filter { item in
                guard let date = item.dueAt ?? item.startsAt else { return false }
                return Calendar.autoupdatingCurrent.isDate(date, inSameDayAs: tomorrow)
            }
            .sorted { ($0.dueAt ?? $0.startsAt ?? .distantFuture) < ($1.dueAt ?? $1.startsAt ?? .distantFuture) }
    }

    private var scheduleConflict: (PlanItem, PlanItem)? {
        let scheduled = todayItems.filter { $0.startsAt != nil && $0.endsAt != nil }

        for firstIndex in scheduled.indices {
            for secondIndex in scheduled.indices where secondIndex > firstIndex {
                let first = scheduled[firstIndex]
                let second = scheduled[secondIndex]

                guard
                    let firstStart = first.startsAt,
                    let firstEnd = first.endsAt,
                    let secondStart = second.startsAt,
                    let secondEnd = second.endsAt
                else { continue }

                let overlaps = firstStart < secondEnd && secondStart < firstEnd
                let sharesMember = !first.memberIDs.isDisjoint(with: second.memberIDs)

                if overlaps && sharesMember {
                    return (first, second)
                }
            }
        }

        return nil
    }

    private var conflictingItemIDs: Set<UUID> {
        guard let scheduleConflict else { return [] }
        return [scheduleConflict.0.id, scheduleConflict.1.id]
    }

    private var attentionCount: Int {
        attentionItems.count + (scheduleConflict == nil ? 0 : 1)
    }

    private var familyBriefText: String {
        if let scheduleConflict {
            let sharedIDs = scheduleConflict.0.memberIDs.intersection(scheduleConflict.1.memberIDs)
            let names = store.members
                .filter { sharedIDs.contains($0.id) }
                .map(\.name)
                .joined(separator: ", ")
            return "\(names.isEmpty ? "Eine Person" : names) hat zwei überlappende Termine. Bitte prüft, wer welchen Termin übernimmt."
        }

        if let nextAttention = attentionItems.first {
            let countText = attentionItems.count == 1
                ? "Ein offener Punkt braucht Aufmerksamkeit."
                : "\(attentionItems.count) offene Punkte brauchen Aufmerksamkeit."
            let dueText = nextAttention.dueAt.map { " Fällig am \(Self.shortDate($0))." } ?? ""
            return "\(countText) Als Nächstes: \(nextAttention.title).\(dueText)"
        }

        if todayItems.isEmpty {
            return "Heute steht aktuell nichts im Plan. Neue Infos kannst du über die Inbox hinzufügen."
        }

        if todayItems.count == 1, let item = todayItems.first {
            return "Heute steht ein Eintrag im Plan: \(item.title)."
        }

        return "Heute stehen \(todayItems.count) Einträge im Plan. Der nächste ist \(todayItems.first?.title ?? "bereits vorbereitet")."
    }

    private var greeting: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: referenceDate)
        switch hour {
        case 5..<12:
            return "Guten Morgen"
        case 12..<18:
            return "Guten Tag"
        default:
            return "Guten Abend"
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                header

                if attentionCount > 0 {
                    attentionSection
                }

                familyBrief

                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Heute", trailing: Self.dayMonth(referenceDate))

                    if todayItems.isEmpty {
                        ContentUnavailableView {
                            Label("Heute ist alles ruhig", systemImage: "checkmark.circle")
                        } description: {
                            Text("Neue Infos kannst du direkt über die Inbox hinzufügen.")
                        } actions: {
                            Button("Etwas hinzufügen") {
                                startInternalAddFlow()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ForEach(todayItems) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                AgendaRow(
                                    item: item,
                                    members: store.members,
                                    showsCompletion: item.kind != .event,
                                    onToggleCompletion: { store.toggleCompletion(item.id) }
                                )

                                if conflictingItemIDs.contains(item.id) {
                                    Label("Terminüberschneidung", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.orange)
                                        .accessibilityLabel("Achtung, Terminüberschneidung")
                                }
                            }

                            if item.id != todayItems.last?.id {
                                Divider().padding(.leading, 74)
                            }
                        }
                    }
                }

                if !tomorrowPreparationItems.isEmpty {
                    prepareSection
                }
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
                    startInternalAddFlow()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Etwas hinzufügen")
                .accessibilityHint("Öffnet einen offenen Import oder startet den internen Text-Testimport")
                .accessibilityIdentifier("today-add")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.longDate(referenceDate))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text(greeting)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Braucht Aufmerksamkeit", trailing: "\(attentionCount)")

            VStack(spacing: 0) {
                if let scheduleConflict {
                    attentionConflictRow(scheduleConflict)

                    if !attentionItems.isEmpty {
                        Divider().padding(.leading, 54)
                    }
                }

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
                                Text(Self.shortDate(due))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)

                        Spacer(minLength: 0)
                        completionButton(for: item)
                    }
                    .padding(14)

                    if item.id != attentionItems.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .accessibilityIdentifier("today-attention")
    }

    private func attentionConflictRow(_ conflict: (PlanItem, PlanItem)) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(.orange.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Zwei Termine überschneiden sich")
                    .font(.subheadline.weight(.semibold))
                Text("\(conflict.0.title) · \(conflict.1.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
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

            Text(familyBriefText)
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

            VStack(spacing: 0) {
                ForEach(tomorrowPreparationItems) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.kind.systemImage)
                            .foregroundStyle(item.kind.tint)
                            .frame(width: 34, height: 34)
                            .background(item.kind.tint.opacity(0.12), in: Circle())
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            Text("morgen fällig")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)

                        Spacer(minLength: 0)
                        completionButton(for: item)
                    }
                    .padding(14)

                    if item.id != tomorrowPreparationItems.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func completionButton(for item: PlanItem) -> some View {
        Button {
            store.toggleCompletion(item.id)
        } label: {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isCompleted ? .green : .secondary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")
        .accessibilityIdentifier("today-item-completion")
    }

    private func startInternalAddFlow() {
        if let pending = store.inboxItems
            .filter({ $0.status == .review || $0.status == .partial })
            .sorted(by: { $0.createdAt > $1.createdAt })
            .first {
            store.openReview(sourceID: pending.id)
        } else {
            store.ingestSchoolLetterText()
        }
    }

    private static func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: date)
    }

    private static func dayMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM"
        return formatter.string(from: date)
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMM"
        return formatter.string(from: date)
    }
}

#Preview("Heute – Busy") {
    NavigationStack {
        TodayView(store: DemoStore(), referenceDate: DemoStore.previewDate(2026, 8, 18, 18, 30))
    }
}

#Preview("Heute – Calm") {
    NavigationStack {
        TodayView(store: DemoStore(scenario: .calmToday), referenceDate: DemoStore.previewDate(2026, 8, 18, 18, 30))
    }
}

#Preview("Heute – Conflict") {
    NavigationStack {
        TodayView(store: DemoStore(scenario: .conflictToday), referenceDate: DemoStore.previewDate(2026, 8, 18, 18, 30))
    }
}

#Preview("Heute – Dark") {
    NavigationStack {
        TodayView(store: DemoStore(), referenceDate: DemoStore.previewDate(2026, 8, 18, 18, 30))
    }
    .preferredColorScheme(.dark)
}

#Preview("Heute – Accessibility") {
    NavigationStack {
        TodayView(store: DemoStore(), referenceDate: DemoStore.previewDate(2026, 8, 18, 18, 30))
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
