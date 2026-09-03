import AVFoundation
import Speech

@MainActor
final class SpeechTranscriber: ObservableObject {
    @Published private(set) var isRecording = false
    @Published var transcript = ""
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var sessionPrefix = ""
    private var committedSessionText = ""
    private var currentHypothesis = ""
    private var currentHypothesisEnd: TimeInterval = 0
    private var activeSessionID: UUID?

    func toggle() async {
        if isRecording { stop(); return }
        await start()
    }

    func stop() {
        stop(sessionID: nil)
    }

    private func stop(sessionID: UUID?) {
        if let sessionID, activeSessionID != sessionID { return }
        activeSessionID = nil
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
    }

    private func start() async {
        let speechStatus = await requestSpeechPermission()
        guard speechStatus == .authorized else {
            errorMessage = "Spracherkennung wurde nicht erlaubt. Du kannst den Rapport weiterhin tippen."
            return
        }
        guard await requestMicrophonePermission() else {
            errorMessage = "Mikrofonzugriff wurde nicht erlaubt. Du kannst den Rapport weiterhin tippen."
            return
        }

        stop()
        sessionPrefix = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        committedSessionText = ""
        currentHypothesis = ""
        currentHypothesisEnd = 0
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest.shouldReportPartialResults = true
            if recognizer?.supportsOnDeviceRecognition == true {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
            request = recognitionRequest
            let sessionID = UUID()
            activeSessionID = sessionID

            let input = audioEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            task = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                Task { @MainActor in
                    guard let self, self.activeSessionID == sessionID else { return }
                    if let result {
                        self.apply(result.bestTranscription)
                    }
                    if error != nil || result?.isFinal == true { self.stop(sessionID: sessionID) }
                }
            }
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            stop()
            errorMessage = "Die Aufnahme konnte nicht gestartet werden: \(error.localizedDescription)"
        }
    }

    private func apply(_ transcription: SFTranscription) {
        let hypothesis = transcription.formattedString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hypothesis.isEmpty else { return }

        let firstTimestamp = transcription.segments.first?.timestamp ?? 0
        let lastSegment = transcription.segments.last
        let hypothesisEnd = (lastSegment?.timestamp ?? 0) + (lastSegment?.duration ?? 0)

        // Speech may discard its previous partial result after a natural pause and
        // continue with timestamps from later in the same audio stream. Preserve
        // that discarded block before displaying the new hypothesis.
        let startsAfterPreviousBlock = !currentHypothesis.isEmpty
            && firstTimestamp > max(0.25, currentHypothesisEnd - 0.25)
        let oldValue = currentHypothesis.lowercased()
        let newValue = hypothesis.lowercased()
        let sharedPrefixCount = zip(oldValue, newValue).prefix { $0.0 == $0.1 }.count
        let isNormalRevision = oldValue.hasPrefix(newValue)
            || newValue.hasPrefix(oldValue)
            || sharedPrefixCount >= 4
        let looksLikeFreshSentence = !currentHypothesis.isEmpty
            && !isNormalRevision
            && hypothesis.count + 8 < currentHypothesis.count
        // A later timestamp alone is not enough: Speech sometimes prunes early
        // segments while its formatted string still contains the existing text.
        // In that case appending would duplicate the whole dictation.
        let beginsNewBlock = (startsAfterPreviousBlock && !isNormalRevision)
            || looksLikeFreshSentence

        if beginsNewBlock {
            committedSessionText = joinedTranscript(prefix: committedSessionText, segment: currentHypothesis)
        }

        currentHypothesis = hypothesis
        currentHypothesisEnd = beginsNewBlock ? hypothesisEnd : max(currentHypothesisEnd, hypothesisEnd)

        let completeSessionText = joinedTranscript(prefix: committedSessionText, segment: currentHypothesis)
        transcript = joinedTranscript(prefix: sessionPrefix, segment: completeSessionText)
    }

    private func joinedTranscript(prefix: String, segment: String) -> String {
        let left = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        let right = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !left.isEmpty else { return right }
        guard !right.isEmpty else { return left }

        let leftComparison = left.lowercased()
        let rightComparison = right.lowercased()
        if rightComparison.hasPrefix(leftComparison) { return right }
        if leftComparison.hasSuffix(rightComparison) { return left }

        let leftWords = left.split(whereSeparator: \.isWhitespace).map(String.init)
        let rightWords = right.split(whereSeparator: \.isWhitespace).map(String.init)
        let normalized: (String) -> String = {
            $0.lowercased().trimmingCharacters(in: .punctuationCharacters)
        }
        let maximumOverlap = min(leftWords.count, rightWords.count)
        for overlap in stride(from: maximumOverlap, through: 1, by: -1) {
            let leftTail = leftWords.suffix(overlap).map(normalized)
            let rightHead = rightWords.prefix(overlap).map(normalized)
            if leftTail == rightHead {
                return (leftWords + Array(rightWords.dropFirst(overlap))).joined(separator: " ")
            }
        }

        return left + " " + right
    }

    private func requestSpeechPermission() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
        }
    }
}
