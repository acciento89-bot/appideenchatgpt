import AVFoundation
import Observation
import PhotosUI
import Speech
import SwiftUI
import UniformTypeIdentifiers

struct CaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore

    @State private var mode: CaptureMode = .menu
    @State private var text = ""
    @State private var title = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var isDocumentPickerPresented = false
    @State private var isCameraPresented = false
    @State private var voice = ReviewSafeVoiceCaptureModel()
    @State private var isPreparing = false
    @State private var errorMessage: String?

    enum CaptureMode: String, CaseIterable, Identifiable {
        case menu, text, photo, document, voice
        var id: Self { self }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .menu: captureMenu
                case .text: textEditor
                case .photo: photoPicker
                case .document: documentPicker
                case .voice: voiceRecorder
                }
            }
            .navigationTitle(mode == .menu ? "Hinzufügen" : modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(mode == .menu ? "Fertig" : "Zurück") {
                        if mode == .menu { dismiss() } else { mode = .menu }
                    }
                }
            }
            .fileImporter(
                isPresented: $isDocumentPickerPresented,
                allowedContentTypes: [.pdf, .image, .plainText],
                allowsMultipleSelection: false
            ) { result in
                Task { await handleDocument(result) }
            }
            .sheet(isPresented: $isCameraPresented) {
                CameraPicker { image in
                    Task { await handleCameraImage(image) }
                }
                .ignoresSafeArea()
            }
            .alert("Import fehlgeschlagen", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Unbekannter Fehler")
            }
            .overlay {
                if isPreparing {
                    ZStack {
                        Color.black.opacity(0.16).ignoresSafeArea()
                        ProgressView("Quelle wird vorbereitet …")
                            .padding(22)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var captureMenu: some View {
        List {
            Section {
                captureRow("Foto aufnehmen", systemImage: "camera.fill") { isCameraPresented = true }
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Foto / Screenshot wählen", systemImage: "photo.on.rectangle.angled")
                        .frame(minHeight: 44)
                }
                .onChange(of: photoItem) { _, newValue in
                    guard newValue != nil else { return }
                    Task { await handlePhotoItem() }
                }
                captureRow("Dokument / PDF importieren", systemImage: "doc.badge.plus") {
                    isDocumentPickerPresented = true
                }
                captureRow("Text eingeben", systemImage: "text.cursor") { mode = .text }
                captureRow("Sprechen", systemImage: "waveform.circle.fill") { mode = .voice }
            } header: {
                Text("Quelle")
            } footer: {
                Text("Fotos, PDFs und Sprache werden zuerst lokal gesichert und dann synchronisiert. Erkannte Aktionen werden immer in „Import prüfen“ bestätigt, bevor sie in den Familienplan gelangen.")
            }
        }
    }

    private var textEditor: some View {
        Form {
            Section("Titel") {
                TextField("z. B. Elternbrief", text: $title)
            }
            Section("Text") {
                TextEditor(text: $text)
                    .frame(minHeight: 220)
            }
            Section {
                Button("Analysieren") {
                    let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty else { return }
                    store.enqueueSourceV1(.init(
                        kind: .text,
                        title: cleanTitle(fallback: "Textimport"),
                        text: clean,
                        fileData: nil,
                        fileName: nil,
                        contentType: "text/plain",
                        extractedText: clean
                    ))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isRepositoryBusy)
            }
        }
    }

    private var photoPicker: some View {
        ContentUnavailableView("Foto wählen", systemImage: "photo")
    }

    private var documentPicker: some View {
        ContentUnavailableView("Dokument wählen", systemImage: "doc")
    }

    private var voiceRecorder: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: voice.isRecording ? "waveform.circle.fill" : "mic.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(voice.isRecording ? .red : .indigo)
                .symbolEffect(.pulse, isActive: voice.isRecording)
                .accessibilityHidden(true)

            Text(voice.isRecording ? "Aufnahme läuft" : "Spracheingabe")
                .font(.title2.bold())

            Text("Sag einfach, was organisiert werden soll. Die App erstellt daraus prüfbare Vorschläge.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if !voice.transcript.isEmpty {
                ScrollView {
                    Text(voice.transcript)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxHeight: 180)
                .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }

            Button {
                Task {
                    if voice.isRecording {
                        guard let (data, transcript) = await voice.stopAndTranscribe() else { return }
                        store.enqueueSourceV1(.init(
                            kind: .voice,
                            title: "Spracheingabe",
                            text: transcript.isEmpty ? nil : transcript,
                            fileData: data,
                            fileName: "Sprache-\(Int(Date().timeIntervalSince1970)).m4a",
                            contentType: "audio/mp4",
                            extractedText: transcript.isEmpty ? nil : transcript
                        ))
                        dismiss()
                    } else {
                        await voice.start()
                    }
                }
            } label: {
                Label(voice.isRecording ? "Aufnahme beenden" : "Aufnahme starten", systemImage: voice.isRecording ? "stop.fill" : "mic.fill")
                    .frame(maxWidth: 280)
            }
            .buttonStyle(.borderedProminent)
            .tint(voice.isRecording ? .red : .indigo)

            if let error = voice.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            Spacer()
        }
        .padding()
    }

    private var modeTitle: String {
        switch mode {
        case .menu: "Hinzufügen"
        case .text: "Text"
        case .photo: "Foto"
        case .document: "Dokument"
        case .voice: "Sprechen"
        }
    }

    @ViewBuilder
    private func captureRow(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(minHeight: 44)
        }
    }

    private func cleanTitle(fallback: String) -> String {
        let clean = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }

    private func handlePhotoItem() async {
        guard let photoItem else { return }
        isPreparing = true
        defer { isPreparing = false; self.photoItem = nil }
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self) else {
                throw FamilyRepositoryError.invalidSource
            }
            let extracted = try? await FamilyOCRService.extractText(from: data, contentType: "image/jpeg")
            store.enqueueSourceV1(.init(
                kind: .image,
                title: "Foto / Screenshot",
                text: nil,
                fileData: data,
                fileName: "Foto-\(Int(Date().timeIntervalSince1970)).jpg",
                contentType: "image/jpeg",
                extractedText: extracted
            ))
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    private func handleDocument(_ result: Result<[URL], Error>) async {
        isPreparing = true
        defer { isPreparing = false }
        do {
            guard let url = try result.get().first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            guard data.count <= 25 * 1024 * 1024 else { throw FamilyRepositoryError.invalidSource }

            let contentType: String
            let kind: SourceKind
            if url.pathExtension.lowercased() == "pdf" {
                contentType = "application/pdf"; kind = .pdf
            } else if ["jpg", "jpeg"].contains(url.pathExtension.lowercased()) {
                contentType = "image/jpeg"; kind = .image
            } else if url.pathExtension.lowercased() == "png" {
                contentType = "image/png"; kind = .image
            } else {
                contentType = "text/plain"; kind = .text
            }

            let extracted: String?
            if kind == .text {
                extracted = String(data: data, encoding: .utf8)
            } else {
                extracted = try? await FamilyOCRService.extractText(from: data, contentType: contentType)
            }

            store.enqueueSourceV1(.init(
                kind: kind,
                title: url.deletingPathExtension().lastPathComponent,
                text: kind == .text ? extracted : nil,
                fileData: kind == .text ? nil : data,
                fileName: url.lastPathComponent,
                contentType: contentType,
                extractedText: extracted
            ))
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    private func handleCameraImage(_ image: UIImage) async {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        isPreparing = true
        defer { isPreparing = false }
        let extracted = try? await FamilyOCRService.extractText(from: data, contentType: "image/jpeg")
        store.enqueueSourceV1(.init(
            kind: .image,
            title: "Foto",
            text: nil,
            fileData: data,
            fileName: "Kamera-\(Int(Date().timeIntervalSince1970)).jpg",
            contentType: "image/jpeg",
            extractedText: extracted
        ))
        dismiss()
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onImage(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

@MainActor
@Observable
private final class ReviewSafeVoiceCaptureModel: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var transcript = ""
    var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var audioURL: URL?

    func start() async {
        errorMessage = nil
        transcript = ""

        do {
            let microphoneGranted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
            guard microphoneGranted else { throw VoiceCaptureError.microphonePermission }

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("family-voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            let recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder.delegate = self
            recorder.prepareToRecord()
            guard recorder.record() else { throw VoiceCaptureError.recordingStart }

            self.recorder = recorder
            audioURL = url
            isRecording = true
        } catch {
            recorder?.stop()
            recorder = nil
            audioURL = nil
            isRecording = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            errorMessage = error.localizedDescription
        }
    }

    func stopAndTranscribe() async -> (Data, String)? {
        recorder?.stop()
        recorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let audioURL, let data = try? Data(contentsOf: audioURL) else {
            errorMessage = VoiceCaptureError.recordingData.localizedDescription
            return nil
        }

        defer {
            try? FileManager.default.removeItem(at: audioURL)
            self.audioURL = nil
        }

        let authorization = await speechAuthorization()
        guard authorization == .authorized else {
            transcript = ""
            return (data, "")
        }

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE")), recognizer.isAvailable else {
            transcript = ""
            return (data, "")
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        do {
            let text: String = try await withCheckedThrowingContinuation { continuation in
                var task: SFSpeechRecognitionTask?
                task = recognizer.recognitionTask(with: request) { result, error in
                    if let error {
                        task?.cancel()
                        continuation.resume(throwing: error)
                        return
                    }
                    if let result, result.isFinal {
                        task?.cancel()
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                }
            }
            transcript = text
            return (data, text)
        } catch {
            // The recording itself is still valid. Speech recognition is an optional
            // enhancement and must never turn a successful recording into a failed import.
            transcript = ""
            return (data, "")
        }
    }

    private func speechAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        let current = SFSpeechRecognizer.authorizationStatus()
        guard current == .notDetermined else { return current }
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    private enum VoiceCaptureError: LocalizedError {
        case microphonePermission
        case recordingStart
        case recordingData

        var errorDescription: String? {
            switch self {
            case .microphonePermission:
                return "Für Sprachaufnahmen wird Mikrofonzugriff benötigt. Bitte erlaube den Zugriff in den iOS-Einstellungen."
            case .recordingStart:
                return "Die Audioaufnahme konnte nicht gestartet werden. Bitte versuche es erneut."
            case .recordingData:
                return "Die Audioaufnahme konnte nicht gespeichert werden. Bitte versuche es erneut."
            }
        }
    }
}
