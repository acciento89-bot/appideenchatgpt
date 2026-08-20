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
                EvidenceFieldsSection(
                    kind: $kind,
                    source: $source,
                    note: $note
                )

                MediaSelectionSection(
                    selectedPhotoItem: $selectedPhotoItem,
                    mediaDraft: $mediaDraft,
                    showsFileImporter: $showsFileImporter,
                    isLoadingMedia: isLoadingMedia
                )

                IntegritySection()
            }
            .navigationTitle("Add Evidence")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave || isLoadingMedia)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await loadPhoto(newItem) }
            }
            .fileImporter(
                isPresented: $showsFileImporter,
                allowedContentTypes: [.pdf, .image, .plainText, .data],
                allowsMultipleSelection: false,
                onCompletion: importFile
            )
            .alert("Could not add evidence", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var canSave: Bool {
        let hasNote = !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasNote || mediaDraft != nil
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
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

private struct EvidenceFieldsSection: View {
    @Binding var kind: EvidenceItemKind
    @Binding var source: String
    @Binding var note: String

    var body: some View {
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
    }
}

private struct MediaSelectionSection: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var mediaDraft: EvidenceMediaDraft?
    @Binding var showsFileImporter: Bool
    let isLoadingMedia: Bool

    var body: some View {
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
                LoadingMediaRow()
            } else if let mediaDraft {
                SelectedMediaSummary(mediaDraft: mediaDraft)

                Button("Remove selected media", role: .destructive) {
                    self.mediaDraft = nil
                    selectedPhotoItem = nil
                }
            }
        }
    }
}

private struct LoadingMediaRow: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Reading original file…")
                .foregroundStyle(.secondary)
        }
    }
}

private struct SelectedMediaSummary: View {
    let originalName: String
    let fileSize: String
    let typeIdentifier: String

    init(mediaDraft: EvidenceMediaDraft) {
        originalName = mediaDraft.originalName
        typeIdentifier = mediaDraft.utTypeIdentifier
        let byteCount = Int64(mediaDraft.data.count)
        fileSize = ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(originalName, systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
            Text(fileSize)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(typeIdentifier)
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
        }
    }
}

private struct IntegritySection: View {
    var body: some View {
        Section("Integrity") {
            Label(
                "The imported original file receives its own SHA-256 hash. The evidence record hash also includes that media hash.",
                systemImage: "number"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("Files are copied into Evidaro's private Application Support storage. The foundation still makes no claim of legal certification or admissibility.")
                .font(.footnote)
                .foregroundStyle(.secondary)
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
