import PDFKit
import QuickLook
import SwiftUI

struct SourceDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    let source: InboxSource

    @State private var document: SourceDocumentData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var temporaryURL: URL?

    var body: some View {
        List {
            Section("Quelle") {
                LabeledContent("Titel", value: source.title)
                LabeledContent("Typ", value: source.kind.displayName)
                LabeledContent("Status", value: source.status.displayName)
                LabeledContent(source.isLocalOnly ? "Erfasst" : "Importiert", value: source.createdAt.formatted(date: .abbreviated, time: .shortened))
                if source.isLocalOnly {
                    LabeledContent("Speicher", value: "Lokal gesichert")
                }
                if let fileName = source.fileName { LabeledContent("Datei", value: fileName) }
                if let bytes = source.sizeBytes { LabeledContent("Größe", value: ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)) }
            }

            if let text = source.sourceText, !text.isEmpty {
                Section("Erkannter Text") {
                    Text(text).textSelection(.enabled)
                }
            }

            if document != nil {
                Section("Original") {
                    Button {
                        Task { await prepareQuickLook() }
                    } label: {
                        Label("Originaldatei öffnen", systemImage: "doc.viewfinder")
                    }
                }
            }

            if source.isLocalOnly {
                Section {
                    Button("Jetzt senden") {
                        store.retryQueuedSourceV1(source.id)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Lokale Quelle verwerfen", role: .destructive) {
                        store.discardQueuedSourceV1(source.id)
                        dismiss()
                    }
                } footer: {
                    Text("Die Quelle bleibt auf diesem Gerät gespeichert, bis die Synchronisierung erfolgreich war oder du sie bewusst verwirfst.")
                }
            } else {
                if source.status == .failed {
                    Section {
                        Button("Analyse erneut versuchen") {
                            store.retrySourceV1(source.id, extractedText: source.sourceText)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                Section {
                    Button(source.isArchived ? "Wiederherstellen" : "Archivieren") {
                        store.archiveSourceV1(source.id, archived: !source.isArchived)
                        dismiss()
                    }
                }
            }

            if let errorMessage {
                Section { Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }
        }
        .navigationTitle("Quelle")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadDocument() }
        .quickLookPreview($temporaryURL)
    }

    private func loadDocument() async {
        guard !source.isLocalOnly, source.storagePath != nil else { return }
        isLoading = true
        defer { isLoading = false }
        do { document = try await SupabaseFamilyRepository().sourceDocument(source.id) }
        catch { errorMessage = error.localizedDescription }
    }

    private func prepareQuickLook() async {
        guard let document else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        do {
            try document.data.write(to: url, options: .atomic)
            temporaryURL = url
        } catch { errorMessage = error.localizedDescription }
    }
}
