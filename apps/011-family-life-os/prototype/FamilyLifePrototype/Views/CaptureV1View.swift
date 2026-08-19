import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct CaptureV1View: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore

    @State private var text = ""
    @State private var title = "Neue Familieninfo"
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isDocumentPickerPresented = false
    @State private var isCameraPresented = false
    @State private var isVoicePresented = false
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Schnell hinzufügen") {
                    Button { isCameraPresented = true } label: {
                        Label("Foto aufnehmen", systemImage: "camera")
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Foto oder Screenshot wählen", systemImage: "photo.on.rectangle")
                    }

                    Button { isDocumentPickerPresented = true } label: {
                        Label("Dokument oder PDF importieren", systemImage: "doc")
                    }

                    Button { isVoicePresented = true } label: {
                        Label("Sprechen", systemImage: "waveform")
                    }
                }

                Section("Text") {
                    TextField("Titel", text: $title)
                    TextEditor(text: $text)
                        .frame(minHeight: 140)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("Text einfügen oder direkt schreiben …")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }

                    Button {
                        ingestText()
                    } label: {
                        HStack {
                            if isBusy { ProgressView() }
                            Text(isBusy ? "Wird verarbeitet …" : "Text analysieren")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Etwas hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task { await importPhoto(newValue) }
            }
            .fileImporter(
                isPresented: $isDocumentPickerPresented,
                allowedContentTypes: [.pdf, .image, .plainText],
                allowsMultipleSelection: false
            ) { result in
                Task { await importDocument(result) }
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraPicker { imageData in
                    isCameraPresented = false
                    guard let imageData else { return }
                    Task { await importData(imageData, fileName: "Foto.jpg", contentType: "image/jpeg", kind: .image, title: "Foto") }
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isVoicePresented) {
                VoiceCaptureSheet(store: store)
            }
        }
    }

    private func ingestText() {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        isBusy = true
        store.ingestSourceV1(
            SourceIngestionRequest(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Textimport" : title,
                kind: .text,
                text: clean
            )
        )
        isBusy = false
        dismiss()
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            errorMessage = "Das Bild konnte nicht gelesen werden."
            return
        }
        await importData(data, fileName: "Foto.jpg", contentType: "image/jpeg", kind: .image, title: "Foto")
    }

    private func importDocument(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let type = UTType(filenameExtension: url.pathExtension)
            let contentType = type?.preferredMIMEType ?? "application/octet-stream"
            let kind: SourceKind = contentType == "application/pdf" ? .pdf : (contentType.starts(with: "image/") ? .image : .text)
            if kind == .text, let text = String(data: data, encoding: .utf8) {
                store.ingestSourceV1(SourceIngestionRequest(title: url.lastPathComponent, kind: .text, text: text))
                dismiss()
            } else {
                await importData(data, fileName: url.lastPathComponent, contentType: contentType, kind: kind, title: url.deletingPathExtension().lastPathComponent)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importData(_ data: Data, fileName: String, contentType: String, kind: SourceKind, title: String) async {
        isBusy = true
        defer { isBusy = false }
        do {
            let extractedText = try await FamilyOCRService.extractText(from: data, contentType: contentType)
            store.ingestSourceV1(
                SourceIngestionRequest(
                    title: title,
                    kind: kind,
                    text: extractedText.isEmpty ? nil : extractedText,
                    fileData: data,
                    fileName: fileName,
                    contentType: contentType
                )
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct VoiceCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    @State private var model = VoiceCaptureModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: model.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(model.isRecording ? .red : .indigo)

                Text(model.isRecording ? "Ich höre zu …" : "Spracheingabe")
                    .font(.title2.bold())

                if !model.transcript.isEmpty {
                    Text(model.transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }

                if model.isRecording {
                    Button("Aufnahme beenden") {
                        Task {
                            guard let (data, transcript) = await model.stopAndTranscribe() else { return }
                            store.ingestSourceV1(
                                SourceIngestionRequest(
                                    title: "Spracheingabe",
                                    kind: .voice,
                                    text: transcript.isEmpty ? nil : transcript,
                                    fileData: data,
                                    fileName: "Sprache.m4a",
                                    contentType: "audio/mp4"
                                )
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Aufnahme starten") { Task { await model.start() } }
                        .buttonStyle(.borderedProminent)
                }

                if let error = model.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Sprechen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let completion: (Data?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let completion: (Data?) -> Void
        init(completion: @escaping (Data?) -> Void) { self.completion = completion }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            completion((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
            picker.dismiss(animated: true)
        }
    }
}
