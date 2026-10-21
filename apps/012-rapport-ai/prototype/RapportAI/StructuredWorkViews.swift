import SwiftUI

private func workKind(_ kind: RapportWorkKind) -> LocalizedStringKey { LocalizedStringKey("work.kind." + kind.rawValue) }
private func workValue(_ item: RapportWorkItem, locale: Locale) -> String {
    if item.kind == .labor { return item.minutes.map { "\($0) min" } ?? "—" }
    guard var quantity = item.quantity else { return "—" }
    return NSDecimalString(&quantity, locale) + " " + item.unit
}

struct StructuredWorkView: View {
    @EnvironmentObject private var store: RapportStore
    @Environment(\.locale) private var locale
    @Binding var draft: RapportDraft
    @State private var editing: RapportWorkItem?
    @State private var deleting: UUID?
    @State private var templateName = ""
    @State private var creatingTemplate = false
    @State private var localError = false
    var body: some View {
        List {
            storageState
            Section("work.narrative") {
                TextEditor(text: $draft.reportText).frame(minHeight: 160)
                Text("work.manualNote").font(.footnote).foregroundStyle(.secondary)
            }
            Section("work.items") {
                ForEach(draft.workItems) { item in
                    Button { editing = item } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.description).font(.headline)
                            Text(workKind(item.kind)).font(.caption)
                            Text(workValue(item, locale: locale)).monospacedDigit()
                        }.foregroundStyle(.primary)
                    }
                    .swipeActions { Button("work.delete", role: .destructive) { deleting = item.id } }
                }
                Button("work.add", systemImage: "plus.circle") { editing = .blank(kind: .labor, description: "", unit: "min") }
                    .disabled(draft.workItems.count >= 1000 || store.loadBlocked)
            }
            Section("work.totals") {
                if let totals = try? RapportWorkTotals(items: draft.workItems) {
                    Text("\(totals.laborMinutes) min")
                    if totals.incompleteCount > 0 { Text("work.unfilled") + Text(" \(totals.incompleteCount)") }
                    ForEach([RapportWorkKind.material, .measurement], id: \.self) { kind in
                        ForEach(Array(Set(draft.workItems.filter { $0.kind == kind && $0.quantity != nil }.map(\.unit))).sorted(), id: \.self) { unit in
                            HStack {
                                Text(workKind(kind))
                                Spacer()
                                Text(decimal(totals.quantity(kind: kind, unit: unit)) + " " + unit).monospacedDigit()
                            }
                        }
                    }
                } else { Text("work.invalid").foregroundStyle(.red) }
                Text("work.unitNote").font(.footnote).foregroundStyle(.secondary)
            }
            Section("work.templates") {
                NavigationLink("work.chooseTemplate") { WorkTemplatesView(draft: $draft) }
                Button("work.saveTemplate") { templateName = ""; creatingTemplate = true }
                    .disabled(draft.workItems.isEmpty || store.loadBlocked)
                Text("work.templateNote").font(.footnote).foregroundStyle(.secondary)
            }
            Section("work.history") {
                NavigationLink("work.openHistory") { WorkHistoryView(reportID: draft.id) }
                    .disabled(!store.reports.contains { $0.id == draft.id })
                Text("work.historyNote").font(.footnote).foregroundStyle(.secondary)
                Button("work.saveReport") { if let saved = store.save(draft) { draft = saved } }
                    .disabled(store.loadBlocked)
            }
            if localError { Text("work.invalid").foregroundStyle(.red) }
        }
        .navigationTitle("work.title")
        .sheet(item: $editing) { item in
            WorkItemEditor(item: item) { changed in
                if let index = draft.workItems.firstIndex(where: { $0.id == changed.id }) { draft.workItems[index] = changed }
                else { draft.workItems.append(changed) }
            }
        }
        .confirmationDialog("work.deleteItem", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("work.delete", role: .destructive) { draft.workItems.removeAll { $0.id == deleting }; deleting = nil }
        }
        .alert("work.saveTemplate", isPresented: $creatingTemplate) {
            TextField("work.templateName", text: $templateName)
            Button("work.cancel", role: .cancel) {}
            Button("work.save") {
                do { _ = store.saveTemplate(try RapportWorkTemplate(name: templateName, trade: draft.trade, items: draft.workItems)) }
                catch { localError = true }
            }.disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
    @ViewBuilder private var storageState: some View {
        if let error = store.errorMessage { Text(LocalizedStringKey(error)).foregroundStyle(.red) }
        if store.loadBlocked { Button("work.retry") { store.reload() } }
    }
    private func decimal(_ value: Decimal) -> String { var value = value; return NSDecimalString(&value, locale) }
}

private struct WorkItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    let item: RapportWorkItem
    let onSave: (RapportWorkItem) -> Void
    @State private var kind: RapportWorkKind
    @State private var description: String
    @State private var minutes: String
    @State private var amount: String
    @State private var unit: String
    @FocusState private var numericFocus: Bool
    init(item: RapportWorkItem, onSave: @escaping (RapportWorkItem) -> Void) {
        self.item = item; self.onSave = onSave
        _kind = State(initialValue: item.kind); _description = State(initialValue: item.description)
        _minutes = State(initialValue: item.minutes.map(String.init) ?? "")
        _amount = State(initialValue: item.quantity.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
        _unit = State(initialValue: item.unit)
    }
    private var validated: RapportWorkItem? {
        let result: RapportWorkItem?
        if kind == .labor {
            result = Int(minutes).flatMap { try? RapportWorkItem.labor(description: description, minutes: $0) }
        } else { result = try? .quantity(kind: kind, description: description, amount: amount, unit: unit) }
        guard var result else { return nil }; result.id = item.id; return result
    }
    var body: some View {
        NavigationStack {
            Form {
                Picker("work.kind", selection: $kind) { ForEach(RapportWorkKind.allCases, id: \.self) { Text(workKind($0)).tag($0) } }
                TextField("work.description", text: $description, axis: .vertical)
                if kind == .labor {
                    TextField("work.minutes", text: $minutes).keyboardType(.numberPad).focused($numericFocus)
                } else {
                    TextField("work.quantity", text: $amount).keyboardType(.decimalPad).focused($numericFocus)
                    TextField("work.unit", text: $unit)
                }
                if validated == nil { Text("work.invalid").font(.footnote).foregroundStyle(.secondary) }
                Text("work.enteredOnly").font(.footnote)
            }
            .navigationTitle("work.item")
            .onChange(of: kind) { _, _ in minutes = ""; amount = ""; unit = kind == .labor ? "min" : "" }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("work.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("work.save") { if let validated { onSave(validated); dismiss() } }.disabled(validated == nil) }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("work.done") { numericFocus = false } }
            }
        }
    }
}

private struct WorkTemplatesView: View {
    @EnvironmentObject private var store: RapportStore
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: RapportDraft
    @State private var selected: RapportWorkTemplate?
    @State private var deleting: RapportWorkTemplate?
    @State private var invalid = false
    var body: some View {
        List {
            Text("work.templateNote").font(.footnote)
            if store.templates.isEmpty { Text("work.noTemplates") }
            ForEach(store.templates) { template in
                Button(template.name) { selected = template }.disabled(store.loadBlocked)
                    .swipeActions { Button("work.delete", role: .destructive) { deleting = template } }
            }
            if invalid { Text("work.tooMany").foregroundStyle(.red) }
            if let error = store.errorMessage { Text(LocalizedStringKey(error)).foregroundStyle(.red) }
        }
        .navigationTitle("work.templates")
        .confirmationDialog("work.applyTemplate", isPresented: Binding(get: { selected != nil }, set: { if !$0 { selected = nil } }), titleVisibility: .visible) {
            Button("work.apply") {
                if let selected {
                    let proposed = draft.workItems + selected.instantiate()
                    if (try? RapportWorkTotals(items: proposed)) != nil { draft.trade = selected.trade; draft.workItems = proposed; dismiss() }
                    else { invalid = true }
                }
                selected = nil
            }
        } message: { Text("work.templateNote") }
        .confirmationDialog("work.deleteTemplate", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("work.delete", role: .destructive) { if let deleting { _ = store.deleteTemplate(deleting.id) }; deleting = nil }
        }
    }
}

struct WorkHistoryView: View {
    @EnvironmentObject private var store: RapportStore
    @Environment(\.locale) private var locale
    let reportID: UUID
    @State private var selected: RapportRevision?
    private var report: RapportDraft? { store.reports.first { $0.id == reportID } }
    var body: some View {
        List {
            Text("work.historyNote").font(.footnote)
            if let report {
                ShareLink(item: report.structuredWorkText(german: locale.language.languageCode?.identifier == "de")) { Label("work.shareHistory", systemImage: "square.and.arrow.up") }
                ForEach(report.revisions.reversed()) { revision in
                    Button { selected = revision } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("work.revision") + Text(" \(revision.number)")
                            Text(revision.at, format: .dateTime.year().month().day().hour().minute())
                            if report.acknowledgements.contains(where: { $0.revisionID == revision.id }) { Text("work.ackRecorded").font(.caption) }
                        }
                    }
                }
            }
            if let error = store.errorMessage { Text(LocalizedStringKey(error)).foregroundStyle(.red) }
        }
        .navigationTitle("work.history")
        .sheet(item: $selected) { revision in WorkRevisionView(reportID: reportID, revision: revision) }
    }
}

private struct WorkRevisionView: View {
    @EnvironmentObject private var store: RapportStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    let reportID: UUID
    let revision: RapportRevision
    @State private var acknowledging = false
    var body: some View {
        NavigationStack {
            List {
                Section("work.revision") {
                    Text("\(revision.number)")
                    Text(revision.at, format: .dateTime.year().month().day().hour().minute())
                    Text(revision.content.customer); Text(revision.content.location); Text(revision.content.system)
                }
                Section("work.originalNotes") { Text(revision.content.rawText).textSelection(.enabled) }
                Section("work.narrative") { Text(revision.content.reportText).textSelection(.enabled) }
                Section("work.items") {
                    ForEach(revision.content.workItems) { item in
                        VStack(alignment: .leading) { Text(item.description); Text(workValue(item, locale: locale)) }
                    }
                }
                Section("work.acknowledgement") {
                    ForEach(store.reports.first(where: { $0.id == reportID })?.acknowledgements.filter { $0.revisionID == revision.id } ?? []) { ack in
                        Text(ack.name); Text(ack.note); Text(ack.at, format: .dateTime.year().month().day().hour().minute())
                    }
                    Button("work.recordAck") { acknowledging = true }.disabled(store.loadBlocked)
                    Text("work.ackBoundary").font(.footnote)
                }
            }
            .navigationTitle("work.readOnly")
            .toolbar { Button("work.done") { dismiss() } }
            .sheet(isPresented: $acknowledging) { WorkAcknowledgementView(reportID: reportID, revision: revision) }
        }
    }
}

private struct WorkAcknowledgementView: View {
    @EnvironmentObject private var store: RapportStore
    @Environment(\.dismiss) private var dismiss
    let reportID: UUID
    let revision: RapportRevision
    @State private var name = ""
    @State private var note = ""
    @State private var confirmed = false
    var body: some View {
        NavigationStack {
            Form {
                Text("work.revision") + Text(" \(revision.number)")
                Text(revision.content.reportText).font(.footnote)
                TextField("work.name", text: $name)
                TextField("work.note", text: $note, axis: .vertical)
                Toggle("work.confirm", isOn: $confirmed)
                Text("work.ackBoundary").font(.footnote)
                if let error = store.errorMessage { Text(LocalizedStringKey(error)).foregroundStyle(.red) }
            }
            .navigationTitle("work.acknowledgement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("work.cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("work.save") { if store.acknowledge(reportID: reportID, revisionID: revision.id, name: name, note: note) { dismiss() } }
                        .disabled(!confirmed || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.loadBlocked)
                }
            }
        }
    }
}
