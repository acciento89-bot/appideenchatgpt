import SwiftUI

struct PlanView: View {
    @Bindable var store: DemoStore
    @State private var selectedMemberIDs: Set<UUID> = []
    @State private var mode: PlanMode = .agenda
    @State private var referenceDate = Date.now
    @State private var editingItem: PlanItem?
    @State private var isCreatingItem = false

    enum PlanMode: String, CaseIterable, Identifiable {
        case agenda = "Agenda"
        case week = "Woche"
        var id: Self { self }
    }

    private struct DayGroup: Identifiable {
        let date: Date
        let title: String
        let items: [PlanItem]
        var id: Date { date }
    }

    private var filteredItems: [PlanItem] {
        store.planItems
            .filter { selectedMemberIDs.isEmpty || !$0.memberIDs.isDisjoint(with: selectedMemberIDs) }
            .filter { item in
                guard mode == .week else { return true }
                guard let date = item.referenceDate,
                      let interval = Calendar.autoupdatingCurrent.dateInterval(of: .weekOfYear, for: referenceDate) else { return false }
                return interval.contains(date)
            }
            .sorted { ($0.referenceDate ?? .distantFuture) < ($1.referenceDate ?? .distantFuture) }
    }

    private var groupedItems: [DayGroup] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full
        let grouped = Dictionary(grouping: filteredItems) { item in
            Calendar.autoupdatingCurrent.startOfDay(for: item.referenceDate ?? .distantFuture)
        }
        return grouped.sorted { $0.key < $1.key }.map {
            DayGroup(date: $0.key, title: formatter.string(from: $0.key), items: $0.value)
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Ansicht", selection: $mode) {
                    ForEach(PlanMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                if mode == .week {
                    weekNavigator
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "Alle", member: nil)
                        ForEach(store.members) { filterChip(title: $0.name, member: $0) }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if groupedItems.isEmpty {
                ContentUnavailableView {
                    Label(mode == .week ? "Diese Woche ist frei" : "Keine Einträge", systemImage: "calendar.badge.checkmark")
                } description: {
                    Text(selectedMemberIDs.isEmpty ? "Füge einen Termin, eine Aufgabe oder Frist hinzu." : "Für diesen Personenfilter gibt es keine Einträge.")
                } actions: {
                    Button("Eintrag hinzufügen") { isCreatingItem = true }.buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedItems) { group in
                    Section(group.title) {
                        ForEach(group.items) { item in
                            Button {
                                editingItem = item
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    AgendaRow(
                                        item: item,
                                        members: store.members,
                                        showsCompletion: item.kind != .event,
                                        onToggleCompletion: { store.toggleCompletion(item.id) }
                                    )
                                    if item.sourceID != nil {
                                        Label("Aus Import", systemImage: "doc.text.magnifyingglass")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) { store.deletePlanItemV1(item.id) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plan")
        .refreshable { await store.refreshHosted() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCreatingItem = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Plan-Eintrag hinzufügen")
            }
        }
        .sheet(isPresented: $isCreatingItem) {
            NavigationStack { PlanEditorView(store: store) }
        }
        .sheet(item: $editingItem) { item in
            NavigationStack { PlanEditorView(store: store, item: item) }
        }
    }

    private var weekNavigator: some View {
        HStack {
            Button { referenceDate = Calendar.autoupdatingCurrent.date(byAdding: .weekOfYear, value: -1, to: referenceDate) ?? referenceDate } label: {
                Image(systemName: "chevron.left").frame(width: 44, height: 44)
            }
            Spacer()
            Button("Diese Woche") { referenceDate = .now }
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button { referenceDate = Calendar.autoupdatingCurrent.date(byAdding: .weekOfYear, value: 1, to: referenceDate) ?? referenceDate } label: {
                Image(systemName: "chevron.right").frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func filterChip(title: String, member: FamilyMember?) -> some View {
        let selected = member.map { selectedMemberIDs.contains($0.id) } ?? selectedMemberIDs.isEmpty
        Button {
            if let member {
                if selectedMemberIDs.contains(member.id) { selectedMemberIDs.remove(member.id) }
                else { selectedMemberIDs.insert(member.id) }
            } else { selectedMemberIDs.removeAll() }
        } label: {
            HStack(spacing: 6) {
                if let member { MemberAvatar(member: member, size: 22).accessibilityHidden(true) }
                Text(title).font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 11).padding(.vertical, 7).frame(minHeight: 44)
            .background(selected ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview { NavigationStack { PlanView(store: DemoStore()) } }
