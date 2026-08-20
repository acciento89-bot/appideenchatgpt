import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct AddEvidenceView: View {
    @ObservedObject var store: EvidenceStore
    let caseID: UUID

    @Environment(\.dismiss) private var dismiss
    @State private var kind: EvidenceItemKind = .observation
    @State private var source = ""
    @State private var note = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaDraft: EvidenceMediaDraft?
    @State private var showsFileImporter = false
    @State private var isLoadingMedia = false
    @State private var errorMessage: String?

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
                            .frame(minHeight: 120)
                    }
                }

                Section("Original media") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose photo", systemImage: "photo.on.rectangle")
                    }

                    Button {
                        showsFileImporter = true
                    } label: {
                        Label("Choose file or PDF", systemImage: "doc.badge.plus")
                    }

                    if isLoadingMedia {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Reading original file…")
                                .foregroundStyle(.secondary)
                        }
                    } else if let mediaDraft {
                        VStack(alignment: .leading, spacing: 5) {
                            Label(mediaDraft.originalName, systemImage: "checkmark.circle.fill")
                                .font(.subheadline.bold())
                            Text(ByteCountFormatter.string(fromByteCount: Int64(mediaDraft.data.count), countStyle: .file))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mediaDraft.utTypeIdentifier)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                        }

                        Button("Remove selected media", role: .destructive) {
                            mediaDraft = nil
                            selectedPhotoItem = nil
                        }
                    }
                }

                Section("Integrity") {
                    Label("The imported original file receives its own SHA-256 hash. The evidence record hash also includes that media hash.", systemImage: "number")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Files are copied into Evidaro's private Application Support storage. The foundation still makes no claim of legal certification or admissibility.")
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
                        save()
                    }
                    .disabled(!canSave || isLoadingMedia)
                }
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem else { return }
                Task { await loadPhoto(newItem) }
            }
            .fileImporter(
                isPresented: $showsFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .data],
                allowsMultipleSelection: false,
                onCompletion: importFile
            )
            .alert("Could not add evidence", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var canSave: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || mediaDraft != nil
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) async {
        isLoadingMedia = true
        defer { isLoadingMedia = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw MediaImportError.noData
            }
            let contentType = item.supportedContentTypes.first ?? .image
            let fileExtension = contentType.preferredFilenameExtension ?? "img"
            mediaDraft = EvidenceMediaDraft(
                data: data,
                originalName: "Photo.\(fileExtension)",
                utTypeIdentifier: contentType.identifier
            )
            kind = .photo
        } catch {
            mediaDraft = nil
            errorMessage = error.localizedDescription
        }
    }

    private func importFile(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription

        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: url)
                let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
                mediaDraft = EvidenceMediaDraft(
                    data: data,
                    originalName: url.lastPathComponent,
                    utTypeIdentifier: contentType?.identifier ?? UTType.data.identifier
                )
                kind = contentType?.conforms(to: .image) == true ? .photo : .document
            } catch {
                mediaDraft = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() {
        do {
            try store.addEvidence(
                caseID: caseID,
                kind: kind,
                source: source,
                note: note,
                media: mediaDraft
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum MediaImportError: LocalizedError {
    case noData

    var errorDescription: String? {
        switch self {
        case .noData:
            "The selected photo could not be read."
        }
    }
}
