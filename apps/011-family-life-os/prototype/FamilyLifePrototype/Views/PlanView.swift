import SwiftUI

struct PlanView: View {
    @Bindable var store: DemoStore
    @State private var selectedMemberIDs: Set<UUID> = []

    private var filteredItems: [PlanItem] {
        store.planItems
            .filter { item in
                selectedMemberIDs.isEmpty || !item.memberIDs.isDisjoint(with: selectedMemberIDs)
            }
            .sorted {
                ($0.startsAt ?? $0.dueAt ?? .distantFuture) < ($1.startsAt ?? $1.dueAt ?? .distantFuture)
            }
    }

    private var groupedItems: [(String, [PlanItem])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateStyle = .full

        let grouped = Dictionary(grouping: filteredItems) { item in
            let date = item.startsAt ?? item.dueAt ?? .distantFuture
            return Calendar.current.startOfDay(for: date)
        }

        return grouped
            .sorted { $0.key < $1.key }
            .map { (formatter.string(from: $0.key), $0.value) }
    }

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(title: "Alle", member: nil)
                        ForEach(store.members) { member in
                            filterChip(title: member.name, member: member)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowBackground(Color.clear)
            }

            ForEach(groupedItems, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            AgendaRow(
                                item: item,
                                members: store.members,
                                showsCompletion: item.kind == .task || item.kind == .preparation,
                                onToggleCompletion: { store.toggleCompletion(item.id) }
                            )

                            if item.sourceID != nil {
                                Label("Aus Import", systemImage: "doc.text.magnifyingglass")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 74)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Plan")
    }

    @ViewBuilder
    private func filterChip(title: String, member: FamilyMember?) -> some View {
        let selected: Bool = {
            guard let member else { return selectedMemberIDs.isEmpty }
            return selectedMemberIDs.contains(member.id)
        }()

        Button {
            if let member {
                if selectedMemberIDs.contains(member.id) {
                    selectedMemberIDs.remove(member.id)
                } else {
                    selectedMemberIDs.insert(member.id)
                }
            } else {
                selectedMemberIDs.removeAll()
            }
        } label: {
            HStack(spacing: 6) {
                if let member {
                    MemberAvatar(member: member, size: 22)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(selected ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.07), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
