import CoreGraphics
import Foundation
import PDFKit
import UIKit
import UniformTypeIdentifiers

struct EvidencePackExportResult: Sendable {
    let url: URL
    let pageCount: Int
    let pdfHash: String
    let currentManifestHash: String
}

enum EvidencePackExportError: LocalizedError {
    case missingCase
    case emptyCase
    case recordIntegrityMismatch(String)
    case missingOriginal(String)
    case originalIntegrityMismatch(String)
    case currentSealMismatch
    case evidenceChangedDuringExport
    case unableToCreatePDF
    case unableToRenderImage(String)
    case unableToRenderPDF(String)

    var errorDescription: String? {
        switch self {
        case .missingCase:
            "The evidence case is no longer available."
        case .emptyCase:
            "Add at least one evidence item before creating an evidence pack."
        case .recordIntegrityMismatch(let item):
            "Evidence record integrity check failed for \(item). The PDF was not created."
        case .missingOriginal(let item):
            "The stored original for \(item) is missing. The PDF was not created."
        case .originalIntegrityMismatch(let item):
            "The stored original for \(item) no longer matches its SHA-256 hash. The PDF was not created."
        case .currentSealMismatch:
            "A seal with the current item count does not match the current manifest. The PDF was not created."
        case .evidenceChangedDuringExport:
            "The evidence case changed while the PDF was being created. The derived PDF was discarded."
        case .unableToCreatePDF:
            "The PDF evidence pack could not be created."
        case .unableToRenderImage(let item):
            "The original image preview for \(item) could not be rendered."
        case .unableToRenderPDF(let item):
            "The original PDF preview for \(item) could not be rendered."
        }
    }
}

private struct EvidencePackSnapshot: Sendable {
    let caseID: UUID
    let title: String
    let kind: String
    let createdAt: Date
    let generatedAt: Date
    let currentManifestHash: String
    let currentSnapshotIsSealed: Bool
    let items: [EvidencePackItemSnapshot]
    let seals: [EvidencePackSealSnapshot]
}

private struct EvidencePackItemSnapshot: Sendable {
    let id: UUID
    let kind: String
    let recordedAt: Date
    let source: String
    let note: String
    let recordHash: String
    let mediaURL: URL?
    let mediaOriginalName: String?
    let mediaUTType: String?
    let mediaHash: String?
    let recognizedText: String?
    let recognizedTextAt: Date?
    let recognizedTextEngine: String?
    let recognizedTextPageCount: Int?
}

private struct EvidencePackSealSnapshot: Sendable, Equatable {
    let id: UUID
    let createdAt: Date
    let itemCount: Int
    let manifestHash: String
}

extension EvidenceStore {
    @discardableResult
    func generateEvidencePack(caseID: UUID) async throws -> EvidencePackExportResult {
        guard let evidenceCase = caseForID(caseID) else {
            throw EvidencePackExportError.missingCase
        }

        let sortedItems = evidenceCase.evidence.sorted { $0.recordedAt < $1.recordedAt }
        guard !sortedItems.isEmpty else {
            throw EvidencePackExportError.emptyCase
        }

        let currentManifestHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: evidenceCase))
        let sameCountSeals = evidenceCase.seals.filter { $0.itemCount == sortedItems.count }
        guard !sameCountSeals.contains(where: { $0.manifestHash != currentManifestHash }) else {
            throw EvidencePackExportError.currentSealMismatch
        }

        var itemSnapshots: [EvidencePackItemSnapshot] = []
        itemSnapshots.reserveCapacity(sortedItems.count)

        for item in sortedItems {
            let expectedRecordHash = EvidenceHasher.itemHash(
                kind: item.kind,
                source: item.source,
                note: item.note,
                recordedAt: item.recordedAt,
                mediaHash: item.mediaHash
            )
            guard item.contentHash == expectedRecordHash else {
                throw EvidencePackExportError.recordIntegrityMismatch(item.mediaOriginalName ?? item.kind.rawValue)
            }

            var storedURL: URL?
            if item.hasMedia {
                guard let url = mediaURL(for: item) else {
                    throw EvidencePackExportError.missingOriginal(item.mediaOriginalName ?? item.kind.rawValue)
                }
                storedURL = url
            }

            itemSnapshots.append(
                EvidencePackItemSnapshot(
                    id: item.id,
                    kind: item.kind.rawValue,
                    recordedAt: item.recordedAt,
                    source: item.source,
                    note: item.note,
                    recordHash: item.contentHash,
                    mediaURL: storedURL,
                    mediaOriginalName: item.mediaOriginalName,
                    mediaUTType: item.mediaUTType,
                    mediaHash: item.mediaHash,
                    recognizedText: item.recognizedText,
                    recognizedTextAt: item.recognizedTextAt,
                    recognizedTextEngine: item.recognizedTextEngine,
                    recognizedTextPageCount: item.recognizedTextPageCount
                )
            )
        }

        let sealSnapshots = evidenceCase.seals
            .map {
                EvidencePackSealSnapshot(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    itemCount: $0.itemCount,
                    manifestHash: $0.manifestHash
                )
            }
            .sorted { $0.createdAt < $1.createdAt }

        let snapshot = EvidencePackSnapshot(
            caseID: evidenceCase.id,
            title: evidenceCase.title,
            kind: evidenceCase.kind.rawValue,
            createdAt: evidenceCase.createdAt,
            generatedAt: Date(),
            currentManifestHash: currentManifestHash,
            currentSnapshotIsSealed: sameCountSeals.contains { $0.manifestHash == currentManifestHash },
            items: itemSnapshots,
            seals: sealSnapshots
        )
        let outputURL = EvidencePackExporter.outputURL(for: evidenceCase.id)

        let rendered = try await Task.detached(priority: .userInitiated) {
            try EvidencePackExporter.render(snapshot: snapshot, outputURL: outputURL)
        }.value

        guard let refreshedCase = caseForID(caseID) else {
            try? FileManager.default.removeItem(at: rendered.url)
            throw EvidencePackExportError.evidenceChangedDuringExport
        }

        let refreshedManifestHash = EvidenceHasher.sha256(EvidenceHasher.canonicalManifest(for: refreshedCase))
        let refreshedItems = Dictionary(uniqueKeysWithValues: refreshedCase.evidence.map { ($0.id, $0) })
        let refreshedSeals = refreshedCase.seals
            .map {
                EvidencePackSealSnapshot(
                    id: $0.id,
                    createdAt: $0.createdAt,
                    itemCount: $0.itemCount,
                    manifestHash: $0.manifestHash
                )
            }
            .sorted { $0.createdAt < $1.createdAt }

        let anchorsStillMatch = refreshedManifestHash == snapshot.currentManifestHash
            && refreshedItems.count == snapshot.items.count
            && snapshot.items.allSatisfy { itemSnapshot in
                guard let item = refreshedItems[itemSnapshot.id] else { return false }
                return item.contentHash == itemSnapshot.recordHash
                    && item.mediaHash == itemSnapshot.mediaHash
            }
            && refreshedSeals == snapshot.seals

        guard anchorsStillMatch else {
            try? FileManager.default.removeItem(at: rendered.url)
            throw EvidencePackExportError.evidenceChangedDuringExport
        }

        return rendered
    }
}

private enum EvidencePackExporter {
    static func outputURL(for caseID: UUID) -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        return appSupport
            .appendingPathComponent("EvidaroExports", isDirectory: true)
            .appendingPathComponent("Evidaro-\(caseID.uuidString.lowercased())-Evidence-Pack.pdf")
    }

    static func render(snapshot: EvidencePackSnapshot, outputURL: URL) throws -> EvidencePackExportResult {
        try verifyOriginalMedia(in: snapshot)

        let pageBounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Evidaro Evidence Pack — \(snapshot.title)",
            kCGPDFContextCreator as String: "Evidaro",
            kCGPDFContextSubject as String: "Local evidence case export"
        ]

        var writer: EvidencePackPDFWriter?
        var renderingError: Error?
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        let pdfData = renderer.pdfData { context in
            let documentWriter = EvidencePackPDFWriter(context: context, bounds: pageBounds, snapshot: snapshot)
            writer = documentWriter
            do {
                try documentWriter.render()
            } catch {
                renderingError = error
            }
        }

        if let renderingError {
            throw renderingError
        }
        guard let writer, writer.pageCount > 0,
              let document = PDFDocument(data: pdfData),
              document.pageCount == writer.pageCount else {
            throw EvidencePackExportError.unableToCreatePDF
        }

        try verifyOriginalMedia(in: snapshot)
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pdfData.write(to: outputURL, options: .atomic)

        return EvidencePackExportResult(
            url: outputURL,
            pageCount: document.pageCount,
            pdfHash: EvidenceHasher.sha256(pdfData),
            currentManifestHash: snapshot.currentManifestHash
        )
    }

    private static func verifyOriginalMedia(in snapshot: EvidencePackSnapshot) throws {
        for item in snapshot.items {
            guard let expectedHash = item.mediaHash else { continue }
            guard let url = item.mediaURL,
                  FileManager.default.fileExists(atPath: url.path) else {
                throw EvidencePackExportError.missingOriginal(item.mediaOriginalName ?? item.kind)
            }
            let data = try Data(contentsOf: url)
            guard EvidenceHasher.sha256(data) == expectedHash else {
                throw EvidencePackExportError.originalIntegrityMismatch(item.mediaOriginalName ?? item.kind)
            }
        }
    }
}

private final class EvidencePackPDFWriter {
    private let context: UIGraphicsPDFRendererContext
    private let bounds: CGRect
    private let snapshot: EvidencePackSnapshot
    private let margin: CGFloat = 44
    private let footerHeight: CGFloat = 32
    private let paragraphSpacing: CGFloat = 8
    private var cursorY: CGFloat = 0
    private var sectionTitle = "Evidence pack"

    private(set) var pageCount = 0

    private var contentWidth: CGFloat { bounds.width - (margin * 2) }
    private var contentBottom: CGFloat { bounds.height - margin - footerHeight }

    init(context: UIGraphicsPDFRendererContext, bounds: CGRect, snapshot: EvidencePackSnapshot) {
        self.context = context
        self.bounds = bounds
        self.snapshot = snapshot
    }

    func render() throws {
        drawCover()

        for (index, item) in snapshot.items.enumerated() {
            try drawEvidenceItem(item, number: index + 1)
        }

        drawSealHistory()
    }

    private func drawCover() {
        beginPage(section: "Evidence pack")
        drawText("EVIDARO", font: .systemFont(ofSize: 14, weight: .bold), color: .darkGray, spacingAfter: 7)
        drawText("EVIDENCE PACK", font: .systemFont(ofSize: 29, weight: .bold), spacingAfter: 12)
        drawText(snapshot.title, font: .systemFont(ofSize: 22, weight: .semibold), spacingAfter: 4)
        drawText(snapshot.kind, font: .systemFont(ofSize: 13, weight: .medium), color: .darkGray, spacingAfter: 20)

        drawRule()
        drawField("Case ID", snapshot.caseID.uuidString, monospaced: true)
        drawField("Case created", format(snapshot.createdAt))
        drawField("Pack generated", format(snapshot.generatedAt))
        drawField("Evidence items", "\(snapshot.items.count)")
        drawField("Snapshot status", snapshot.currentSnapshotIsSealed ? "Current timeline matches a recorded snapshot seal" : "Current timeline is not represented by a matching seal")
        drawField("Current manifest SHA-256", snapshot.currentManifestHash, monospaced: true)

        ensureSpace(150)
        drawRule()
        drawText("Integrity model", font: .systemFont(ofSize: 15, weight: .bold), spacingAfter: 7)
        drawText(
            "Original media bytes remain the source of truth. Before this PDF is created, Evidaro re-checks each stored original against its recorded SHA-256 and re-checks each evidence-record hash. The PDF is a derived presentation and does not replace the originals.",
            font: .systemFont(ofSize: 10.5),
            color: .darkGray,
            spacingAfter: 8
        )
        drawText(
            "Image and PDF pages shown inside this pack are previews rendered from the verified originals. Original files remain separately exportable from the case timeline.",
            font: .systemFont(ofSize: 10.5),
            color: .darkGray,
            spacingAfter: 8
        )
        drawText(
            "Recognized text is derived locally with Apple Vision. OCR is clearly labeled, can be refreshed, and is excluded from original-media hashes, evidence-record hashes and snapshot seals.",
            font: .systemFont(ofSize: 10.5),
            color: .darkGray,
            spacingAfter: 8
        )
        drawText(
            "Integrity aid only. Evidaro does not provide legal advice, notarization, independent timestamp certification or a guarantee of admissibility.",
            font: .systemFont(ofSize: 10.5, weight: .semibold),
            spacingAfter: 0
        )
    }

    private func drawEvidenceItem(_ item: EvidencePackItemSnapshot, number: Int) throws {
        beginPage(section: "Evidence #\(number)")
        drawText("EVIDENCE #\(number)", font: .systemFont(ofSize: 12, weight: .bold), color: .darkGray, spacingAfter: 6)
        drawText(item.kind, font: .systemFont(ofSize: 22, weight: .bold), spacingAfter: 14)

        drawField("Recorded", format(item.recordedAt))
        if !item.source.isEmpty {
            drawField("Source / context", item.source)
        }
        if !item.note.isEmpty {
            drawField("User note", item.note)
        }
        if let originalName = item.mediaOriginalName {
            drawField("Original file", originalName)
        }
        if let mediaType = item.mediaUTType {
            drawField("Original media type", mediaType)
        }
        if let mediaHash = item.mediaHash {
            drawField("Original media SHA-256", mediaHash, monospaced: true)
        }
        drawField("Evidence record SHA-256", item.recordHash, monospaced: true)

        if item.recognizedTextAt != nil {
            ensureSpace(90)
            drawRule()
            drawText("DERIVED OCR — NOT ORIGINAL EVIDENCE", font: .systemFont(ofSize: 12, weight: .bold), spacingAfter: 6)
            if let engine = item.recognizedTextEngine {
                drawField("OCR engine", engine)
            }
            if let recognizedAt = item.recognizedTextAt {
                drawField("Recognized", format(recognizedAt))
            }
            if let pageCount = item.recognizedTextPageCount {
                drawField("OCR source pages/images", "\(pageCount)")
            }
            let text = item.recognizedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if text.isEmpty {
                drawText("No text detected.", font: .systemFont(ofSize: 10.5), color: .darkGray, spacingAfter: 8)
            } else {
                drawText(text, font: .systemFont(ofSize: 10.5), spacingAfter: 8)
            }
            drawText(
                "OCR is derived metadata and is not included in the original media SHA-256, evidence-record SHA-256 or snapshot seals.",
                font: .systemFont(ofSize: 9.5),
                color: .darkGray,
                spacingAfter: 0
            )
        }

        guard let mediaURL = item.mediaURL,
              let mediaHash = item.mediaHash,
              let typeIdentifier = item.mediaUTType,
              let contentType = UTType(typeIdentifier) else {
            return
        }

        let originalData = try Data(contentsOf: mediaURL)
        guard EvidenceHasher.sha256(originalData) == mediaHash else {
            throw EvidencePackExportError.originalIntegrityMismatch(item.mediaOriginalName ?? item.kind)
        }

        if contentType.conforms(to: .image) {
            guard let image = UIImage(data: originalData) else {
                throw EvidencePackExportError.unableToRenderImage(item.mediaOriginalName ?? item.kind)
            }
            drawImagePreview(image, item: item, number: number)
        } else if contentType.conforms(to: .pdf) {
            guard let document = PDFDocument(data: originalData), document.pageCount > 0 else {
                throw EvidencePackExportError.unableToRenderPDF(item.mediaOriginalName ?? item.kind)
            }
            for pageIndex in 0..<document.pageCount {
                guard let page = document.page(at: pageIndex) else {
                    throw EvidencePackExportError.unableToRenderPDF(item.mediaOriginalName ?? item.kind)
                }
                drawPDFPagePreview(page, item: item, number: number, pageIndex: pageIndex, pageCount: document.pageCount)
            }
        }
    }

    private func drawImagePreview(_ image: UIImage, item: EvidencePackItemSnapshot, number: Int) {
        beginPage(section: "Evidence #\(number) • original preview")
        drawText("ORIGINAL MEDIA PREVIEW", font: .systemFont(ofSize: 12, weight: .bold), color: .darkGray, spacingAfter: 5)
        drawText(item.mediaOriginalName ?? "Image original", font: .systemFont(ofSize: 16, weight: .semibold), spacingAfter: 10)

        let imageBottom = contentBottom - 58
        let available = CGRect(x: margin, y: cursorY, width: contentWidth, height: max(imageBottom - cursorY, 80))
        image.draw(in: aspectFitRect(imageSize: image.size, inside: available))
        cursorY = imageBottom + 8
        drawText("Preview rendered from the verified original. Original SHA-256:", font: .systemFont(ofSize: 8.5), color: .darkGray, spacingAfter: 3)
        drawText(item.mediaHash ?? "", font: .monospacedSystemFont(ofSize: 7.5, weight: .regular), color: .darkGray, spacingAfter: 0)
    }

    private func drawPDFPagePreview(
        _ page: PDFPage,
        item: EvidencePackItemSnapshot,
        number: Int,
        pageIndex: Int,
        pageCount: Int
    ) {
        beginPage(section: "Evidence #\(number) • original PDF preview")
        drawText("ORIGINAL PDF PREVIEW • PAGE \(pageIndex + 1) OF \(pageCount)", font: .systemFont(ofSize: 11.5, weight: .bold), color: .darkGray, spacingAfter: 5)
        drawText(item.mediaOriginalName ?? "PDF original", font: .systemFont(ofSize: 15, weight: .semibold), spacingAfter: 10)

        let previewBottom = contentBottom - 58
        let available = CGRect(x: margin, y: cursorY, width: contentWidth, height: max(previewBottom - cursorY, 80))
        let thumbnail = page.thumbnail(
            of: CGSize(width: available.width * 2, height: available.height * 2),
            for: .mediaBox
        )
        thumbnail.draw(in: aspectFitRect(imageSize: thumbnail.size, inside: available))
        cursorY = previewBottom + 8
        drawText("Preview rendered from the verified original PDF. Original SHA-256:", font: .systemFont(ofSize: 8.5), color: .darkGray, spacingAfter: 3)
        drawText(item.mediaHash ?? "", font: .monospacedSystemFont(ofSize: 7.5, weight: .regular), color: .darkGray, spacingAfter: 0)
    }

    private func drawSealHistory() {
        beginPage(section: "Snapshot seals")
        drawText("SNAPSHOT SEALS", font: .systemFont(ofSize: 22, weight: .bold), spacingAfter: 8)
        drawText(
            "A seal records a manifest hash for a snapshot at that moment. Later evidence can create a newer snapshot without rewriting older recorded seal values.",
            font: .systemFont(ofSize: 10.5),
            color: .darkGray,
            spacingAfter: 14
        )

        if snapshot.seals.isEmpty {
            drawText("No snapshot seal has been recorded for this case.", font: .systemFont(ofSize: 11), spacingAfter: 10)
        } else {
            for (index, seal) in snapshot.seals.sorted(by: { $0.createdAt > $1.createdAt }).enumerated() {
                ensureSpace(94)
                let isCurrent = seal.itemCount == snapshot.items.count && seal.manifestHash == snapshot.currentManifestHash
                drawText(
                    "Seal \(snapshot.seals.count - index)\(isCurrent ? " • CURRENT SNAPSHOT" : " • HISTORICAL")",
                    font: .systemFont(ofSize: 11.5, weight: .bold),
                    spacingAfter: 4
                )
                drawField("Recorded", format(seal.createdAt), compact: true)
                drawField("Item count", "\(seal.itemCount)", compact: true)
                drawField("Manifest SHA-256", seal.manifestHash, monospaced: true, compact: true)
                cursorY += 8
            }
        }

        ensureSpace(88)
        drawRule()
        drawField("Current manifest SHA-256", snapshot.currentManifestHash, monospaced: true)
        drawText(
            snapshot.currentSnapshotIsSealed
                ? "The current exported timeline matches at least one recorded snapshot seal."
                : "The current exported timeline is not represented by a matching recorded snapshot seal.",
            font: .systemFont(ofSize: 10.5, weight: .semibold),
            spacingAfter: 8
        )
        drawText(
            "Integrity aid only. Seal values do not independently prove when a real-world event occurred and do not guarantee acceptance by a court, insurer, employer or authority.",
            font: .systemFont(ofSize: 9.5),
            color: .darkGray,
            spacingAfter: 0
        )
    }

    private func beginPage(section: String) {
        sectionTitle = section
        context.beginPage()
        pageCount += 1
        UIColor.white.setFill()
        context.cgContext.fill(bounds)
        cursorY = margin

        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .semibold),
            .foregroundColor: UIColor.darkGray
        ]
        NSString(string: "EVIDARO • \(section.uppercased())").draw(
            in: CGRect(x: margin, y: 20, width: contentWidth, height: 16),
            withAttributes: headerAttributes
        )

        let footer = "Evidaro • \(snapshot.caseID.uuidString.prefix(8)) • Page \(pageCount)"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.darkGray
        ]
        NSString(string: footer).draw(
            in: CGRect(x: margin, y: bounds.height - 31, width: contentWidth, height: 14),
            withAttributes: footerAttributes
        )
    }

    private func ensureSpace(_ height: CGFloat) {
        if cursorY + height > contentBottom {
            beginPage(section: sectionTitle + " • continued")
        }
    }

    private func drawRule() {
        ensureSpace(14)
        let y = cursorY + 2
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: y))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: y))
        context.cgContext.strokePath()
        cursorY += 14
    }

    private func drawField(
        _ label: String,
        _ value: String,
        monospaced: Bool = false,
        compact: Bool = false
    ) {
        ensureSpace(compact ? 42 : 50)
        drawText(label.uppercased(), font: .systemFont(ofSize: compact ? 8.5 : 9, weight: .bold), color: .darkGray, spacingAfter: 2)
        drawText(
            value,
            font: monospaced
                ? .monospacedSystemFont(ofSize: compact ? 8 : 8.5, weight: .regular)
                : .systemFont(ofSize: compact ? 9.5 : 10.5),
            spacingAfter: compact ? 5 : 9
        )
    }

    private func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor = .black,
        spacingAfter: CGFloat = 8
    ) {
        let availableWidth = contentWidth
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let lines = wrappedLines(text, font: font, width: availableWidth)

        for line in lines {
            let display = line.isEmpty ? " " : line
            let measured = NSString(string: display).boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            let lineHeight = max(ceil(measured.height), font.lineHeight)
            ensureSpace(lineHeight + 1)
            NSString(string: display).draw(
                in: CGRect(x: margin, y: cursorY, width: availableWidth, height: lineHeight + 2),
                withAttributes: attributes
            )
            cursorY += lineHeight + 1
        }
        cursorY += spacingAfter
    }

    private func wrappedLines(_ text: String, font: UIFont, width: CGFloat) -> [String] {
        let paragraphs = text.components(separatedBy: CharacterSet.newlines)
        var output: [String] = []

        for paragraph in paragraphs {
            let words = paragraph.split(whereSeparator: { $0.isWhitespace }).map(String.init)
            guard !words.isEmpty else {
                output.append("")
                continue
            }

            var current = ""
            for word in words {
                let candidate = current.isEmpty ? word : current + " " + word
                if current.isEmpty || textWidth(candidate, font: font) <= width {
                    current = candidate
                } else {
                    output.append(current)
                    current = word
                }
            }
            if !current.isEmpty {
                output.append(current)
            }
        }

        return output.isEmpty ? [""] : output
    }

    private func textWidth(_ text: String, font: UIFont) -> CGFloat {
        NSString(string: text).size(withAttributes: [.font: font]).width
    }

    private func aspectFitRect(imageSize: CGSize, inside bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.string(from: date)
    }
}

#if DEBUG
private extension EvidenceStore {
    static var evidencePackSmokeCaseID: UUID {
        UUID(uuidString: "44444444-4444-4444-8444-444444444444")!
    }

    func prepareEvidencePackSmoke() async throws -> String {
        guard let evidenceCase = caseForID(Self.evidencePackSmokeCaseID),
              let item = evidenceCase.evidence.first,
              let seal = evidenceCase.seals.first else {
            throw EvidencePackSmokeError.missingFixture
        }

        let mediaHash = item.mediaHash ?? ""
        let recordHash = item.contentHash
        let sealHash = seal.manifestHash
        let result = try await generateEvidencePack(caseID: Self.evidencePackSmokeCaseID)
        try validateEvidencePackSmoke(
            url: result.url,
            expectedMediaHash: mediaHash,
            expectedRecordHash: recordHash,
            expectedSealHash: sealHash
        )

        guard let refreshed = caseForID(Self.evidencePackSmokeCaseID),
              let refreshedItem = refreshed.evidence.first,
              let refreshedSeal = refreshed.seals.first,
              refreshedItem.mediaHash == mediaHash,
              refreshedItem.contentHash == recordHash,
              refreshedSeal.manifestHash == sealHash else {
            throw EvidencePackSmokeError.integrityChangedAfterExport
        }

        return "pack-prepared pages=\(result.pageCount) pdfHash=\(result.pdfHash) mediaHash=\(mediaHash) recordHash=\(recordHash) seal=\(sealHash)"
    }

    func verifyEvidencePackSmoke() throws -> String {
        guard let evidenceCase = caseForID(Self.evidencePackSmokeCaseID),
              let item = evidenceCase.evidence.first,
              let seal = evidenceCase.seals.first else {
            throw EvidencePackSmokeError.missingFixture
        }

        let mediaHash = item.mediaHash ?? ""
        let recordHash = item.contentHash
        let sealHash = seal.manifestHash
        let url = EvidencePackExporter.outputURL(for: Self.evidencePackSmokeCaseID)
        let data = try Data(contentsOf: url)
        let pdfHash = EvidenceHasher.sha256(data)
        let pageCount = try validateEvidencePackSmoke(
            url: url,
            expectedMediaHash: mediaHash,
            expectedRecordHash: recordHash,
            expectedSealHash: sealHash
        )

        guard item.mediaHash == mediaHash,
              item.contentHash == recordHash,
              seal.manifestHash == sealHash else {
            throw EvidencePackSmokeError.integrityChangedAfterExport
        }

        return "pack-verified pages=\(pageCount) pdfHash=\(pdfHash) mediaHash=\(mediaHash) recordHash=\(recordHash) seal=\(sealHash)"
    }

    @discardableResult
    func validateEvidencePackSmoke(
        url: URL,
        expectedMediaHash: String,
        expectedRecordHash: String,
        expectedSealHash: String
    ) throws -> Int {
        guard let document = PDFDocument(url: url), document.pageCount >= 4 else {
            throw EvidencePackSmokeError.invalidPDF
        }
        let extractedText = document.string ?? ""
        let requiredTokens = [
            "EVIDARO",
            "EVIDENCE PACK",
            "CI OCR Smoke",
            Self.evidencePackSmokeCaseID.uuidString,
            "Original media SHA-256",
            expectedMediaHash,
            "Evidence record SHA-256",
            expectedRecordHash,
            "DERIVED OCR",
            "EVIDARO 4827",
            "SNAPSHOT SEALS",
            expectedSealHash,
            "Integrity aid only"
        ]
        for token in requiredTokens where extractedText.range(of: token, options: .caseInsensitive) == nil {
            throw EvidencePackSmokeError.missingPDFToken(token)
        }
        return document.pageCount
    }
}

private enum EvidencePackSmokeError: LocalizedError {
    case missingFixture
    case invalidPDF
    case missingPDFToken(String)
    case integrityChangedAfterExport

    var errorDescription: String? {
        switch self {
        case .missingFixture:
            "The OCR fixture required for the evidence-pack smoke test is missing."
        case .invalidPDF:
            "The evidence-pack smoke export is not a readable multi-page PDF."
        case .missingPDFToken(let token):
            "The evidence-pack PDF is missing required text: \(token)"
        case .integrityChangedAfterExport:
            "Creating the PDF evidence pack changed an original media, record or seal hash."
        }
    }
}
#endif
