import SwiftUI

struct AddEvidenceView: View {
    @ObservedObject var store: EvidenceStore
    let caseID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var kind: EvidenceItemKind = .observation
    @State private var source = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Evidence") {
                    Picker("Type", selection: $kind) {
                        ForEach(EvidenceItemKind.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol)
                                .tag(option)
                        }
                    }

                    TextField("Source or context (optional)", text: $source)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Factual note")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $note)
                            .frame(minHeight: 130)
                    }
                }

                Section("Integrity") {
                    Label("A SHA-256 hash is generated from this item's canonical metadata when you save it.", systemImage: "number")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Foundation build: photo and document labels are placeholders for the real media-intake pass. This screen currently stores the factual note and context only.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Evidence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.addEvidence(caseID: caseID, kind: kind, source: source, note: note)
                        dismiss()
                    }
                    .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
