import SwiftUI

struct PlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    let item: PlanItem?

    @State private var draft: PlanItemDraft
    @State private var hasStart = false
    @State private var hasEnd = false
    @State private var hasDue = false
    @State private var startDate = Date.now
    @State private var endDate = Date.now.addingTimeInterval(3600)
    @State private var dueDate = Date.now
    @State private var amountText = ""
    @State private var deleteConfirmation = false

    init(store: DemoStore, item: PlanItem? = nil) {
        self.store = store
        self.item = item
        let initial = item.map(PlanItemDraft.init(item:)) ?? PlanItemDraft()
        _draft = State(initialValue: initial)
        _hasStart = State(initialValue: initial.startsAt != nil)
        _hasEnd = State(initialValue: initial.endsAt != nil)
        _hasDue = State(initialValue: initial.dueAt != nil)
        _startDate = State(initialValue: initial.startsAt ?? .now)
        _endDate = State(initialValue: initial.endsAt ?? .now.addingTimeInterval(3600))
        _dueDate = State(initialValue: initial.dueAt ?? .now)
        if let amount = initial.amountMinor { _amountText = State(initialValue: String(format: "%.2f", Double(amount) / 100)) }
    }

    var body: some View {
        Form {
            Section("Art") {
                Picker("Art", selection: $draft.kind) {
                    ForEach(PlanKind.allCases, id: \.self) { kind in
                        Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                    }
                }
            }

            Section("Details") {
                TextField("Titel", text: $draft.title)
                TextField("Ort", text: Binding($draft.location, replacingNilWith: ""))
                TextField("Notiz", text: Binding($draft.note, replacingNilWith: ""), axis: .vertical)
                    .lineLimit(2...5)
            }

            Section("Zeit") {
                Toggle("Start", isOn: $hasStart)
                if hasStart {
                    DatePicker("Beginn", selection: $startDate)
                }
                Toggle("Ende", isOn: $hasEnd)
                if hasEnd {
                    DatePicker("Ende", selection: $endDate)
                }
                Toggle("Fälligkeit", isOn: $hasDue)
                if hasDue {
                    DatePicker("Fällig", selection: $dueDate)
                }
            }

            if draft.kind == .payment {
                Section("Zahlung") {
                    TextField("Betrag in €", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Währung", text: Binding($draft.currency, replacingNilWith: "EUR"))
                        .textInputAutocapitalization(.characters)
                }
            }

            Section("Zuständig") {
                ForEach(store.members) { member in
                    Button {
                        if draft.memberIDs.contains(member.id) { draft.memberIDs.remove(member.id) }
                        else { draft.memberIDs.insert(member.id) }
                    } label: {
                        HStack {
                            MemberAvatar(member: member, size: 32)
                            Text(member.name)
                            Spacer()
                            Image(systemName: draft.memberIDs.contains(member.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(draft.memberIDs.contains(member.id) ? .indigo : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if item != nil {
                Section {
                    Button("Eintrag löschen", role: .destructive) { deleteConfirmation = true }
                }
            }
        }
        .navigationTitle(item == nil ? "Neu" : "Bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Sichern") { save() }
                    .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isRepositoryBusy)
            }
        }
        .confirmationDialog("Eintrag wirklich löschen?", isPresented: $deleteConfirmation, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                if let item { store.deletePlanItemV1(item.id); dismiss() }
            }
        }
    }

    private func save() {
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.startsAt = hasStart ? startDate : nil
        draft.endsAt = hasEnd ? endDate : nil
        draft.dueAt = hasDue ? dueDate : nil
        if draft.kind == .payment {
            let normalized = amountText.replacingOccurrences(of: ",", with: ".")
            if let value = Double(normalized) { draft.amountMinor = Int((value * 100).rounded()) }
        } else {
            draft.amountMinor = nil
        }

        if let item { store.updatePlanItemV1(item, draft: draft) }
        else { store.createPlanItemV1(draft) }
        dismiss()
    }
}

private extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith fallback: String) {
        self.init(
            get: { source.wrappedValue ?? fallback },
            set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
        )
    }
}
