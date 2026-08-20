import PhotosUI
import SwiftUI
import UIKit
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
    @State private var showsCamera = false
    @State private var isLoadingMedia = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                EvidenceFieldsSection(kind: $kind, source: $source, note: $note)

                MediaSelectionSection(
                    selectedPhotoItem: $selectedPhotoItem,
                    mediaDraft: $mediaDraft,
                    showsFileImporter: $showsFileImporter,
                    showsCamera: $showsCamera,
                    isLoadingMedia: isLoadingMedia
                )

                IntegritySection()
            }
            .navigationTitle("evidence.add.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save", action: save)
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
            .fullScreenCover(isPresented: $showsCamera) {
                CameraCaptureView(
                    onCapture: { draft in
                        mediaDraft = draft
                        selectedPhotoItem = nil
                        kind = .photo
                        showsCamera = false
                    },
                    onCancel: { showsCamera = false },
                    onError: { error in
                        showsCamera = false
                        errorMessage = error.localizedDescription
                    }
                )
                .ignoresSafeArea()
            }
            .alert("evidence.alert_add_failed", isPresented: errorAlertBinding) {
                Button("common.ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? L10n.string("common.unknown_error"))
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
                if !isPresented { errorMessage = nil }
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
                if accessed { url.stopAccessingSecurityScopedResource() }
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
        Section("evidence.section") {
            Picker("case.type", selection: $kind) {
                ForEach(EvidenceItemKind.allCases) { option in
                    Label(option.localizedName, systemImage: option.symbol).tag(option)
                }
            }
            TextField("evidence.source_placeholder", text: $source)
            VStack(alignment: .leading, spacing: 8) {
                Text("evidence.factual_note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $note)
                    .frame(minHeight: 120)
                    .accessibilityLabel(Text("evidence.factual_note"))
            }
        }
    }
}

private struct MediaSelectionSection: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var mediaDraft: EvidenceMediaDraft?
    @Binding var showsFileImporter: Bool
    @Binding var showsCamera: Bool
    let isLoadingMedia: Bool

    var body: some View {
        Section("media.section") {
            Button {
                showsCamera = true
            } label: {
                Label("media.take_photo", systemImage: "camera")
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("media.choose_photo", systemImage: "photo.on.rectangle")
            }

            Button {
                showsFileImporter = true
            } label: {
                Label("media.choose_file", systemImage: "doc.badge.plus")
            }

            if isLoadingMedia {
                LoadingMediaRow()
            } else if let mediaDraft {
                SelectedMediaSummary(mediaDraft: mediaDraft)
                Button("media.remove", role: .destructive) {
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
            Text("media.reading").foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct SelectedMediaSummary: View {
    let originalName: String
    let fileSize: String
    let typeIdentifier: String

    init(mediaDraft: EvidenceMediaDraft) {
        originalName = mediaDraft.originalName
        typeIdentifier = mediaDraft.utTypeIdentifier
        fileSize = ByteCountFormatter.string(
            fromByteCount: Int64(mediaDraft.data.count),
            countStyle: .file
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(originalName, systemImage: "checkmark.circle.fill")
                .font(.subheadline.bold())
            Text(fileSize).font(.caption).foregroundStyle(.secondary)
            Text(typeIdentifier).font(.caption2.monospaced()).foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct IntegritySection: View {
    var body: some View {
        Section("integrity.section") {
            Label(
                L10n.string("integrity.media_hash_help"),
                systemImage: "number"
            )
            .font(.footnote)
            .foregroundStyle(.secondary)

            Text("integrity.storage_help")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: (EvidenceMediaDraft) -> Void
    let onCancel: () -> Void
    let onError: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 1.0) else {
                parent.onError(MediaImportError.cameraEncodingFailed)
                return
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd-HHmmss"
            let name = "Camera-\(formatter.string(from: Date())).jpg"
            parent.onCapture(
                EvidenceMediaDraft(
                    data: data,
                    originalName: name,
                    utTypeIdentifier: UTType.jpeg.identifier
                )
            )
        }
    }
}

private enum MediaImportError: LocalizedError {
    case noData
    case cameraEncodingFailed

    var errorDescription: String? {
        switch self {
        case .noData:
            L10n.string("evidence.error_photo_read")
        case .cameraEncodingFailed:
            L10n.string("evidence.error_camera_encode")
        }
    }
}
