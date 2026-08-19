import SwiftUI

struct PlanEditorV1View: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    let item: PlanItem?

    @State private var kind: PlanKind
    @State private var title: String
    @State private var startsAt: Date
    @State private var hasStart: Bool
    @State private var dueAt: Date
    @State private var hasDue: Bool
    @State private var location: String
    @State private var note: String
    @State private var amountText: String
    @State private var selectedMemberIDs: Set<UUID>

    init(store: DemoStore, item: PlanItem? = nil) {
        self.store = store
        self.item = item
        _kind = State(initialValue: item?.kind ?? .task)
        _title = State(initialValue: item?.title ?? "")
        _startsAt = State(initialValue: item?.startsAt ?? .now)
        _hasStart = State(initialValue: item?.startsAt != nil)
        _dueAt = State(initialValue: item?.dueAt ?? .now)
        _hasDue = State(initialValue: item?.dueAt != nil)
        _location = State(initialValue: item?.location ?? "")
        _note = State(initialValue: item?.note ?? "")
        if let amount = item?.amountMinor { _amountText = State(initialValue: String(format: "%.2f", Double(amount) / 100)) }
        else { _amountText = State(initialValue: "") }
        _selectedMemberIDs = State(initialValue: item?.memberIDs ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Eintrag") {
                    Picker("Typ", selection: $kind) {
                        ForEach(PlanKind.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    TextField("Titel", text: $title)
                }

                Section("Zeit") {
                    Toggle("Startzeit", isOn: $hasStart)
                    if hasStart {
                        DatePicker("Start", selection: $startsAt)
                    }
                    Toggle("Fälligkeit", isOn: $hasDue)
                    if hasDue {
                        DatePicker("Fällig", selection: $dueAt)
                    }
                }

                Section("Familie") {
                    ForEach(store.members) { member in
                        Button {
                            if selectedMemberIDs.contains(member.id) { selectedMemberIDs.remove(member.id) }
                            else { selectedMemberIDs.insert(member.id) }
                        } label: {
                            HStack {
                                MemberAvatar(member: member, size: 32)
                                Text(member.name)
                                Spacer()
                                Image(systemName: selectedMemberIDs.contains(member.id) ? "checkmark.circle.fill" : "circle")
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Details") {
                    TextField("Ort", text: $location)
                    TextField("Notiz", text: $note, axis: .vertical)
                    if kind == .payment {
                        TextField("Betrag in €", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                }

                if let item {
                    Section {
                        Button("Eintrag löschen", role: .destructive) {
                            store.deletePlanItemV1(item.id)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "Neu im Plan" : "Eintrag bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let amountMinor = Int((Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0) * 100)
                        let draft = PlanItemDraft(
                            kind: kind,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            startsAt: hasStart ? startsAt : nil,
                            endsAt: nil,
                            dueAt: hasDue ? dueAt : nil,
                            allDay: false,
                            location: location.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                            amountMinor: kind == .payment && !amountText.isEmpty ? amountMinor : nil,
                            currency: kind == .payment ? "EUR" : nil,
                            memberIDs: selectedMemberIDs
                        )
                        if let item { store.updatePlanItemV1(item, draft: draft) }
                        else { store.createPlanItemV1(draft) }
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
