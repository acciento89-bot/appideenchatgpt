import Combine
import CryptoKit
import Foundation
import PDFKit
import SwiftData
import UIKit
import UniformTypeIdentifiers
import Vision

@MainActor
final class EvidenceStore: ObservableObject {
    let container: ModelContainer
    private let context: ModelContext
    private let mediaDirectory: URL

    @Published private var revision = 0

    init(inMemory: Bool = false, seedDemoData: Bool = true) {
        do {
            let schema = Schema([
                EvidenceCase.self,
                EvidenceItem.self,
                EvidenceSeal.self
            ])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)

            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            mediaDirectory = appSupport.appendingPathComponent("EvidaroMedia", isDirectory: true)
            try FileManager.default.createDirectory(
                at: mediaDirectory,
                withIntermediateDirectories: true
            )

            if seedDemoData && fetchCases().isEmpty {
                seedDemoCase()
            }
        } catch {
            fatalError("Unable to create Evidaro local store: \(error)")
        }
    }

    var cases: [EvidenceCase] {
        _ = revision
        return fetchCases().sorted { $0.lastActivity > $1.lastActivity }
    }

    var totalEvidenceCount: Int {
        cases.reduce(0) { $0 + $1.evidence.count }
    }

    var totalSealCount: Int {
        cases.reduce(0) { $0 + $1.seals.count }
    }

    func caseForID(_ id: UUID) -> EvidenceCase? {
        cases.first { $0.id == id }
    }

    func createCase(title: String, kind: EvidenceCaseKind) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }

        let evidenceCase = EvidenceCase(
            title: cleanTitle,
            kind: kind,
            createdAt: Date()
        )
        context.insert(evidenceCase)
        saveAndRefresh()
    }

    func addEvidence(
        caseID: UUID,
        kind: EvidenceItemKind,
        source: String,
        note: String,
        media: EvidenceMediaDraft? = nil
    ) throws {
        guard let evidenceCase = caseForID(caseID) else { return }

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNote.isEmpty || media != nil else { return }

        let recordedAt = Date()
        let itemID = UUID()
        let mediaHash = media.map { EvidenceHasher.sha256($0.data) }
        let storedMedia = try media.map { try persistMedia($0, itemID: itemID) }
        let contentHash = EvidenceHasher.itemHash(
            kind: kind,
            source: cleanSource,
            note: cleanNote,
            recordedAt: recordedAt,
            mediaHash: mediaHash
        )

        let item = EvidenceItem(
            id: itemID,
            kind: kind,
            recordedAt: recordedAt,
            source: cleanSource,
            note: cleanNote,
            contentHash: contentHash,
            mediaFileName: storedMedia?.storedName,
            mediaOriginalName: media?.originalName,
            mediaUTType: media?.utTypeIdentifier,
            mediaHash: mediaHash
        )

        evidenceCase.evidence.append(item)
        saveAndRefresh()
    }

    @discardableResult
    func seal(caseID: UUID) -> EvidenceSeal? {
        guard let evidenceCase = caseForID(caseID), !evidenceCase.evidence.isEmpty else {
            return nil
        }

        let manifest = EvidenceHasher.canonicalManifest(for: evidenceCase)
        let seal = EvidenceSeal(
            createdAt: Date(),
            itemCount: evidenceCase.evidence.count,
            manifestHash: EvidenceHasher.sha256(manifest)
        )
        evidenceCase.seals.append(seal)
        saveAndRefresh()
        return seal
    }

    func mediaURL(for item: EvidenceItem) -> URL? {
        guard let mediaFileName = item.mediaFileName else { return nil }
        let url = mediaDirectory.appendingPathComponent(mediaFileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    func canRecognizeText(for item: EvidenceItem) -> Bool {
        guard item.hasMedia,
              let identifier = item.mediaUTType,
              let contentType = UTType(identifier) else {
            return false
        }
        return contentType.conforms(to: .image) || contentType.conforms(to: .pdf)
    }

    @discardableResult
    func recognizeText(caseID: UUID, itemID: UUID) async throws -> EvidenceOCRResult {
        guard let evidenceCase = caseForID(caseID),
              let item = evidenceCase.evidence.first(where: { $0.id == itemID }) else {
            throw EvidenceOCRError.missingEvidence
        }
        guard canRecognizeText(for: item),
              let mediaURL = mediaURL(for: item),
              let expectedMediaHash = item.mediaHash,
              let typeIdentifier = item.mediaUTType else {
            throw EvidenceOCRError.unsupportedMedia
        }

        let expectedRecordHash = item.contentHash
        let result = try await Task.detached(priority: .userInitiated) {
            let originalData = try Data(contentsOf: mediaURL)
            let actualMediaHash = EvidenceHasher.sha256(originalData)
            guard actualMediaHash == expectedMediaHash else {
                throw EvidenceOCRError.mediaIntegrityMismatch
            }
            return try EvidenceOCR.recognize(
                data: originalData,
                typeIdentifier: typeIdentifier
            )
        }.value

        guard let refreshedCase = caseForID(caseID),
              let refreshedItem = refreshedCase.evidence.first(where: { $0.id == itemID }) else {
            throw EvidenceOCRError.missingEvidence
        }
        guard refreshedItem.mediaHash == expectedMediaHash,
              refreshedItem.contentHash == expectedRecordHash else {
            throw EvidenceOCRError.evidenceChangedDuringRecognition
        }

        refreshedItem.recognizedText = result.text
        refreshedItem.recognizedTextAt = Date()
        refreshedItem.recognizedTextEngine = result.engine
        refreshedItem.recognizedTextPageCount = result.pageCount
        try context.save()
        revision += 1
        return result
    }

    func shareManifest(caseID: UUID) -> String {
        guard let evidenceCase = caseForID(caseID) else { return "" }

        var lines: [String] = [
            "KAMILUNAVO TRACE EVIDENCE MANIFEST",
            "Case: \(evidenceCase.title)",
            "Type: \(evidenceCase.kind.rawValue)",
            "Case ID: \(evidenceCase.id.uuidString)",
            "Created: \(evidenceCase.createdAt.formatted(date: .abbreviated, time: .standard))",
            "",
            "Evidence items: \(evidenceCase.evidence.count)"
        ]

        for (offset, item) in evidenceCase.evidence.sorted(by: { $0.recordedAt < $1.recordedAt }).enumerated() {
            lines.append("")
            lines.append("#\(offset + 1) \(item.kind.rawValue)")
            lines.append("Recorded: \(item.recordedAt.formatted(date: .abbreviated, time: .standard))")
            if !item.source.isEmpty {
                lines.append("Source: \(item.source)")
            }
            if !item.note.isEmpty {
                lines.append("Note: \(item.note)")
            }
            if let originalName = item.mediaOriginalName {
                lines.append("Original file: \(originalName)")
            }
            if let mediaHash = item.mediaHash {
                lines.append("Original media SHA-256: \(mediaHash)")
            }
            lines.append("Evidence record SHA-256: \(item.contentHash)")
        }

        if let latestSeal = evidenceCase.seals.max(by: { $0.createdAt < $1.createdAt }) {
            lines.append("")
            lines.append("LATEST SNAPSHOT SEAL")
            lines.append("Sealed: \(latestSeal.createdAt.formatted(date: .abbreviated, time: .standard))")
            lines.append("Items: \(latestSeal.itemCount)")
            lines.append("Manifest SHA-256: \(latestSeal.manifestHash)")
        } else {
            lines.append("")
            lines.append("No snapshot has been sealed yet.")
        }

        lines.append("")
        lines.append("Recognized text is intentionally excluded from this integrity manifest because OCR is derived data and may be refreshed without changing the original evidence bytes.")
        lines.append("Integrity aid only. Kamilunavo Trace does not provide legal advice or guarantee admissibility.")
        return lines.joined(separator: "\n")
    }

    private func fetchCases() -> [EvidenceCase] {
        (try? context.fetch(FetchDescriptor<EvidenceCase>())) ?? []
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            revision += 1
        } catch {
            assertionFailure("Evidaro persistence save failed: \(error)")
        }
    }

    private func seedDemoCase() {
        let now = Date()
        let caseCreatedAt = now.addingTimeInterval(-7_400)
        let firstRecordedAt = now.addingTimeInterval(-7_200)
        let secondRecordedAt = now.addingTimeInterval(-6_900)

        let firstNote = "Package arrived with a crushed upper-right corner and a visible tear along the seam."
        let firstSource = "Front door delivery"
        let firstItem = EvidenceItem(
            kind: .observation,
            recordedAt: firstRecordedAt,
            source: firstSource,
            note: firstNote,
            contentHash: EvidenceHasher.itemHash(
                kind: .observation,
                source: firstSource,
                note: firstNote,
                recordedAt: firstRecordedAt,
                mediaHash: nil
            )
        )

        let secondNote = "Outer packaging retained. Contents not yet discarded."
        let secondSource = "Follow-up note"
        let secondItem = EvidenceItem(
            kind: .observation,
            recordedAt: secondRecordedAt,
            source: secondSource,
            note: secondNote,
            contentHash: EvidenceHasher.itemHash(
                kind: .observation,
                source: secondSource,
                note: secondNote,
                recordedAt: secondRecordedAt,
                mediaHash: nil
            )
        )

        let evidenceCase = EvidenceCase(
            title: "Damaged delivery",
            kind: .delivery,
            createdAt: caseCreatedAt,
            evidence: [firstItem, secondItem]
        )
        context.insert(evidenceCase)
        saveAndRefresh()
    }

    private func persistMedia(
        _ media: EvidenceMediaDraft,
        itemID: UUID
    ) throws -> (storedName: String, url: URL) {
        let originalExtension = (media.originalName as NSString).pathExtension
        let safeExtension = originalExtension.isEmpty ? "bin" : originalExtension.lowercased()
        let storedName = "\(itemID.uuidString).\(safeExtension)"
        let url = mediaDirectory.appendingPathComponent(storedName)
        try media.data.write(to: url, options: .atomic)
        return (storedName, url)
    }

#if DEBUG
    private static let smokeCaseID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
    private static let smokeItemID = UUID(uuidString: "22222222-2222-4222-8222-222222222222")!
    private static let smokeSealID = UUID(uuidString: "33333333-3333-4333-8333-333333333333")!
    private static let smokeCreatedAt = Date(timeIntervalSince1970: 1_787_000_000)
    private static let smokeRecordedAt = Date(timeIntervalSince1970: 1_787_000_120)
    private static let smokeMediaData = Data("evidaro-persistence-smoke-media-v1".utf8)

    private static let ocrSmokeCaseID = UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
    private static let ocrSmokeItemID = UUID(uuidString: "55555555-5555-4555-8555-555555555555")!
    private static let ocrSmokeSealID = UUID(uuidString: "66666666-6666-4666-8666-666666666666")!
    private static let ocrSmokeCreatedAt = Date(timeIntervalSince1970: 1_787_100_000)
    private static let ocrSmokeRecordedAt = Date(timeIntervalSince1970: 1_787_100_120)

    func preparePersistenceSmoke() throws -> String {
        if let existing = fetchCases().first(where: { $0.id == Self.smokeCaseID }) {
            for item in existing.evidence {
                if let url = mediaURL(for: item) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            context.delete(existing)
            try context.save()
        }

        let media = EvidenceMediaDraft(
            data: Self.smokeMediaData,
            originalName: "persistence-smoke.bin",
            utTypeIdentifier: "public.data"
        )
        let mediaHash = EvidenceHasher.sha256(media.data)
        let storedMedia = try persistMedia(media, itemID: Self.smokeItemID)
        let note = "Process-relaunch persistence smoke"
        let source = "GitHub Actions simulator"
        let contentHash = EvidenceHasher.itemHash(
            kind: .document,
            source: source,
            note: note,
            recordedAt: Self.smokeRecordedAt,
            mediaHash: mediaHash
        )

        let item = EvidenceItem(
            id: Self.smokeItemID,
            kind: .document,
            recordedAt: Self.smokeRecordedAt,
            source: source,
            note: note,
            contentHash: contentHash,
            mediaFileName: storedMedia.storedName,
            mediaOriginalName: media.originalName,
            mediaUTType: media.utTypeIdentifier,
            mediaHash: mediaHash
        )
        let evidenceCase = EvidenceCase(
            id: Self.smokeCaseID,
            title: "CI Persistence Smoke",
            kind: .other,
            createdAt: Self.smokeCreatedAt,
            evidence: [item]
        )
        context.insert(evidenceCase)

        let seal = EvidenceSeal(
            id: Self.smokeSealID,
            createdAt: Self.smokeRecordedAt.addingTimeInterval(60),
            itemCount: 1,
            manifestHash: EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        )
        evidenceCase.seals.append(seal)
        try context.save()
        revision += 1

        return "prepared case=\(evidenceCase.id.uuidString) mediaHash=\(mediaHash) seal=\(seal.manifestHash)"
    }

    func verifyPersistenceSmoke() throws -> String {
        guard let evidenceCase = fetchCases().first(where: { $0.id == Self.smokeCaseID }) else {
            throw PersistenceSmokeError.missingCase
        }
        guard evidenceCase.evidence.count == 1,
              let item = evidenceCase.evidence.first(where: { $0.id == Self.smokeItemID }) else {
            throw PersistenceSmokeError.missingEvidence
        }
        guard evidenceCase.seals.count == 1,
              let seal = evidenceCase.seals.first(where: { $0.id == Self.smokeSealID }) else {
            throw PersistenceSmokeError.missingSeal
        }
        guard let mediaURL = mediaURL(for: item) else {
            throw PersistenceSmokeError.missingMedia
        }

        let storedData = try Data(contentsOf: mediaURL)
        guard storedData == Self.smokeMediaData else {
            throw PersistenceSmokeError.mediaBytesChanged
        }
        let expectedMediaHash = EvidenceHasher.sha256(storedData)
        guard item.mediaHash == expectedMediaHash else {
            throw PersistenceSmokeError.mediaHashMismatch
        }
        let expectedItemHash = EvidenceHasher.itemHash(
            kind: item.kind,
            source: item.source,
            note: item.note,
            recordedAt: item.recordedAt,
            mediaHash: item.mediaHash
        )
        guard item.contentHash == expectedItemHash else {
            throw PersistenceSmokeError.itemHashMismatch
        }
        let expectedSealHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        guard seal.itemCount == 1, seal.manifestHash == expectedSealHash else {
            throw PersistenceSmokeError.sealMismatch
        }

        return "verified case=\(evidenceCase.id.uuidString) mediaHash=\(expectedMediaHash) seal=\(expectedSealHash)"
    }

    func prepareOCRSmoke() async throws -> String {
        if let existing = fetchCases().first(where: { $0.id == Self.ocrSmokeCaseID }) {
            for item in existing.evidence {
                if let url = mediaURL(for: item) {
                    try? FileManager.default.removeItem(at: url)
                }
            }
            context.delete(existing)
            try context.save()
        }

        let fixtureData = try makeOCRFixturePNG()
        let media = EvidenceMediaDraft(
            data: fixtureData,
            originalName: "ocr-smoke.png",
            utTypeIdentifier: UTType.png.identifier
        )
        let mediaHash = EvidenceHasher.sha256(media.data)
        let storedMedia = try persistMedia(media, itemID: Self.ocrSmokeItemID)
        let note = "OCR derivation must not change sealed evidence"
        let source = "GitHub Actions Vision smoke"
        let contentHash = EvidenceHasher.itemHash(
            kind: .photo,
            source: source,
            note: note,
            recordedAt: Self.ocrSmokeRecordedAt,
            mediaHash: mediaHash
        )

        let item = EvidenceItem(
            id: Self.ocrSmokeItemID,
            kind: .photo,
            recordedAt: Self.ocrSmokeRecordedAt,
            source: source,
            note: note,
            contentHash: contentHash,
            mediaFileName: storedMedia.storedName,
            mediaOriginalName: media.originalName,
            mediaUTType: media.utTypeIdentifier,
            mediaHash: mediaHash
        )
        let evidenceCase = EvidenceCase(
            id: Self.ocrSmokeCaseID,
            title: "CI OCR Smoke",
            kind: .other,
            createdAt: Self.ocrSmokeCreatedAt,
            evidence: [item]
        )
        context.insert(evidenceCase)

        let sealHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        let seal = EvidenceSeal(
            id: Self.ocrSmokeSealID,
            createdAt: Self.ocrSmokeRecordedAt.addingTimeInterval(60),
            itemCount: 1,
            manifestHash: sealHash
        )
        evidenceCase.seals.append(seal)
        try context.save()
        revision += 1

        let result = try await recognizeText(caseID: Self.ocrSmokeCaseID, itemID: Self.ocrSmokeItemID)
        let normalized = result.text.uppercased()
        guard normalized.contains("EVIDARO"), normalized.contains("4827") else {
            throw OCRSmokeError.expectedTextMissing(result.text)
        }
        guard item.mediaHash == mediaHash,
              item.contentHash == contentHash,
              seal.manifestHash == sealHash else {
            throw OCRSmokeError.integrityChangedAfterOCR
        }

        return "ocr-prepared text=\(result.text.replacingOccurrences(of: "\n", with: " ")) mediaHash=\(mediaHash) recordHash=\(contentHash) seal=\(sealHash)"
    }

    func verifyOCRSmoke() throws -> String {
        guard let evidenceCase = fetchCases().first(where: { $0.id == Self.ocrSmokeCaseID }),
              let item = evidenceCase.evidence.first(where: { $0.id == Self.ocrSmokeItemID }),
              let seal = evidenceCase.seals.first(where: { $0.id == Self.ocrSmokeSealID }),
              let mediaURL = mediaURL(for: item) else {
            throw OCRSmokeError.missingPersistedOCRFixture
        }

        let storedData = try Data(contentsOf: mediaURL)
        let expectedMediaHash = EvidenceHasher.sha256(storedData)
        let expectedRecordHash = EvidenceHasher.itemHash(
            kind: item.kind,
            source: item.source,
            note: item.note,
            recordedAt: item.recordedAt,
            mediaHash: item.mediaHash
        )
        let expectedSealHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        let normalizedText = (item.recognizedText ?? "").uppercased()

        guard item.mediaHash == expectedMediaHash else {
            throw OCRSmokeError.mediaHashMismatch
        }
        guard item.contentHash == expectedRecordHash else {
            throw OCRSmokeError.recordHashMismatch
        }
        guard seal.manifestHash == expectedSealHash else {
            throw OCRSmokeError.sealHashMismatch
        }
        guard item.recognizedTextAt != nil,
              item.recognizedTextEngine == EvidenceOCR.engineName,
              item.recognizedTextPageCount == 1,
              normalizedText.contains("EVIDARO"),
              normalizedText.contains("4827") else {
            throw OCRSmokeError.derivedTextDidNotPersist
        }

        return "ocr-verified text=\((item.recognizedText ?? "").replacingOccurrences(of: "\n", with: " ")) mediaHash=\(expectedMediaHash) recordHash=\(expectedRecordHash) seal=\(expectedSealHash)"
    }

    private func makeOCRFixturePNG() throws -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: 1200, height: 420)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 104, weight: .bold),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraph
            ]
            NSString(string: "EVIDARO 4827").draw(
                in: CGRect(x: 40, y: 125, width: 1120, height: 150),
                withAttributes: attributes
            )
        }
        guard let data = image.pngData() else {
            throw OCRSmokeError.fixtureEncodingFailed
        }
        return data
    }
#endif
}

struct EvidenceOCRResult: Sendable {
    let text: String
    let pageCount: Int
    let engine: String
}

enum EvidenceOCRError: LocalizedError {
    case missingEvidence
    case unsupportedMedia
    case mediaIntegrityMismatch
    case evidenceChangedDuringRecognition
    case invalidPDF
    case pdfPageRenderingFailed(Int)

    var errorDescription: String? {
        switch self {
        case .missingEvidence:
            "The evidence item is no longer available."
        case .unsupportedMedia:
            "Text recognition is available for images and PDFs."
        case .mediaIntegrityMismatch:
            "The stored original file no longer matches its SHA-256 hash, so text recognition was stopped."
        case .evidenceChangedDuringRecognition:
            "The evidence record changed while text recognition was running. No derived text was saved."
        case .invalidPDF:
            "The PDF could not be opened for local text recognition."
        case .pdfPageRenderingFailed(let page):
            "PDF page \(page) could not be rendered for local text recognition."
        }
    }
}

private enum EvidenceOCR {
    static let engineName = "Apple Vision on-device"

    static func recognize(data: Data, typeIdentifier: String) throws -> EvidenceOCRResult {
        guard let contentType = UTType(typeIdentifier) else {
            throw EvidenceOCRError.unsupportedMedia
        }

        if contentType.conforms(to: .pdf) {
            return try recognizePDF(data)
        }
        if contentType.conforms(to: .image) {
            let text = try recognizeImageData(data)
            return EvidenceOCRResult(text: text, pageCount: 1, engine: engineName)
        }
        throw EvidenceOCRError.unsupportedMedia
    }

    private static func recognizeImageData(_ data: Data) throws -> String {
        let request = makeRequest()
        let handler = VNImageRequestHandler(data: data, options: [:])
        try handler.perform([request])
        return text(from: request)
    }

    private static func recognizePDF(_ data: Data) throws -> EvidenceOCRResult {
        guard let document = PDFDocument(data: data), document.pageCount > 0 else {
            throw EvidenceOCRError.invalidPDF
        }

        var pageTexts: [String] = []
        pageTexts.reserveCapacity(document.pageCount)

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else {
                throw EvidenceOCRError.pdfPageRenderingFailed(index + 1)
            }
            let bounds = page.bounds(for: .mediaBox)
            let longestSide = max(bounds.width, bounds.height)
            let scale = longestSide > 0 ? min(2200 / longestSide, 3) : 1
            let targetSize = CGSize(
                width: max(bounds.width * scale, 1),
                height: max(bounds.height * scale, 1)
            )
            let image = page.thumbnail(of: targetSize, for: .mediaBox)
            guard let cgImage = image.cgImage else {
                throw EvidenceOCRError.pdfPageRenderingFailed(index + 1)
            }

            let request = makeRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            let pageText = text(from: request)
            if !pageText.isEmpty {
                pageTexts.append("Page \(index + 1)\n\(pageText)")
            }
        }

        return EvidenceOCRResult(
            text: pageTexts.joined(separator: "\n\n"),
            pageCount: document.pageCount,
            engine: engineName
        )
    }

    private static func makeRequest() -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = 0.01
        return request
    }

    private static func text(from request: VNRecognizeTextRequest) -> String {
        (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#if DEBUG
private enum PersistenceSmokeError: LocalizedError {
    case missingCase
    case missingEvidence
    case missingSeal
    case missingMedia
    case mediaBytesChanged
    case mediaHashMismatch
    case itemHashMismatch
    case sealMismatch

    var errorDescription: String? {
        switch self {
        case .missingCase: "Persistence smoke case did not survive process restart."
        case .missingEvidence: "Persistence smoke evidence did not survive process restart."
        case .missingSeal: "Persistence smoke seal did not survive process restart."
        case .missingMedia: "Persistence smoke media reference did not survive process restart."
        case .mediaBytesChanged: "Persistence smoke media bytes changed after process restart."
        case .mediaHashMismatch: "Persistence smoke media hash no longer matches stored bytes."
        case .itemHashMismatch: "Persistence smoke evidence-record hash no longer matches persisted fields."
        case .sealMismatch: "Persistence smoke seal no longer matches the persisted manifest."
        }
    }
}

private enum OCRSmokeError: LocalizedError {
    case fixtureEncodingFailed
    case expectedTextMissing(String)
    case integrityChangedAfterOCR
    case missingPersistedOCRFixture
    case mediaHashMismatch
    case recordHashMismatch
    case sealHashMismatch
    case derivedTextDidNotPersist

    var errorDescription: String? {
        switch self {
        case .fixtureEncodingFailed:
            "The OCR smoke fixture image could not be encoded."
        case .expectedTextMissing(let text):
            "Vision did not recognize the expected OCR smoke text. Result: \(text)"
        case .integrityChangedAfterOCR:
            "OCR changed an original evidence hash or pre-existing seal."
        case .missingPersistedOCRFixture:
            "The OCR smoke fixture did not survive process restart."
        case .mediaHashMismatch:
            "The original media SHA-256 changed after OCR/restart."
        case .recordHashMismatch:
            "The evidence record SHA-256 changed after OCR/restart."
        case .sealHashMismatch:
            "The pre-OCR snapshot seal changed after OCR/restart."
        case .derivedTextDidNotPersist:
            "The derived OCR result did not survive process restart."
        }
    }
}
#endif

enum EvidenceHasher {
    static func itemHash(
        kind: EvidenceItemKind,
        source: String,
        note: String,
        recordedAt: Date,
        mediaHash: String?
    ) -> String {
        let canonical = [
            "kind=\(kind.rawValue)",
            "recordedAt=\(recordedAt.timeIntervalSince1970)",
            "source=\(source)",
            "note=\(note)",
            "mediaHash=\(mediaHash ?? "none")"
        ].joined(separator: "\n")
        return sha256(canonical)
    }

    static func canonicalManifest(for evidenceCase: EvidenceCase) -> String {
        var lines = [
            "caseID=\(evidenceCase.id.uuidString)",
            "title=\(evidenceCase.title)",
            "kind=\(evidenceCase.kind.rawValue)",
            "createdAt=\(evidenceCase.createdAt.timeIntervalSince1970)"
        ]

        for item in evidenceCase.evidence.sorted(by: { $0.recordedAt < $1.recordedAt }) {
            lines.append(
                "item=\(item.id.uuidString)|\(item.recordedAt.timeIntervalSince1970)|\(item.contentHash)|\(item.mediaHash ?? "none")"
            )
        }

        return lines.joined(separator: "\n")
    }

    static func sha256(_ value: String) -> String {
        sha256(Data(value.utf8))
    }

    static func sha256(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
