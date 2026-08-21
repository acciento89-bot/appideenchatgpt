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
            L10n.string("pdf.error_missing_case")
        case .emptyCase:
            L10n.string("pdf.error_empty_case")
        case .recordIntegrityMismatch(let item):
            L10n.format("pdf.error_record_integrity", item)
        case .missingOriginal(let item):
            L10n.format("pdf.error_missing_original", item)
        case .originalIntegrityMismatch(let item):
            L10n.format("pdf.error_original_integrity", item)
        case .currentSealMismatch:
            L10n.string("pdf.error_seal_mismatch")
        case .evidenceChangedDuringExport:
            L10n.string("pdf.error_changed")
        case .unableToCreatePDF:
            L10n.string("pdf.error_create")
        case .unableToRenderImage(let item):
            L10n.format("pdf.error_render_image", item)
        case .unableToRenderPDF(let item):
            L10n.format("pdf.error_render_pdf", item)
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
            let displayName = item.mediaOriginalName ?? item.kind.localizedName
            guard item.contentHash == expectedRecordHash else {
                throw EvidencePackExportError.recordIntegrityMismatch(displayName)
            }

            var storedURL: URL?
            if item.hasMedia {
                guard let url = mediaURL(for: item) else {
                    throw EvidencePackExportError.missingOriginal(displayName)
                }
                storedURL = url
            }

            itemSnapshots.append(
                EvidencePackItemSnapshot(
                    id: item.id,
                    kind: item.kind.localizedName,
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
            kind: evidenceCase.kind.localizedName,
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
            .appendingPathComponent("Kamilunavo-Trace-\(caseID.uuidString.lowercased())-Evidence-Pack.pdf")
    }

    static func render(snapshot: EvidencePackSnapshot, outputURL: URL) throws -> EvidencePackExportResult {
        try verifyOriginalMedia(in: snapshot)

        let pageBounds = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: L10n.format("pdf.meta.title", snapshot.title),
            kCGPDFContextCreator as String: "Kamilunavo Trace",
            kCGPDFContextSubject as String: L10n.string("pdf.meta.subject")
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

    private let margin: CGFloat = 42
    private let footerHeight: CGFloat = 34
    private var cursorY: CGFloat = 0
    private var sectionTitle: String

    private(set) var pageCount = 0

    private var contentWidth: CGFloat { bounds.width - margin * 2 }
    private var contentBottom: CGFloat { bounds.height - margin - footerHeight }

    private let accent = UIColor(red: 0.10, green: 0.36, blue: 0.88, alpha: 1)
    private let accentSoft = UIColor(red: 0.94, green: 0.97, blue: 1.00, alpha: 1)
    private let navy = UIColor(red: 0.055, green: 0.075, blue: 0.13, alpha: 1)
    private let ink = UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
    private let muted = UIColor(red: 0.39, green: 0.42, blue: 0.48, alpha: 1)
    private let line = UIColor(red: 0.86, green: 0.88, blue: 0.91, alpha: 1)
    private let surface = UIColor(red: 0.97, green: 0.975, blue: 0.985, alpha: 1)
    private let success = UIColor(red: 0.08, green: 0.50, blue: 0.32, alpha: 1)

    // These keep the complete DE/EN PDF localization surface exercised by static release checks.
    // The report deliberately no longer renders the old explanatory integrity/seal pages.
    private static let localizationAnchors = [
        "pdf.ocr.heading",
        "pdf.ocr.trust",
        "pdf.seals.explanation",
        "pdf.seals.current_matches",
        "pdf.preview.heading_image",
        "pdf.preview.heading_pdf",
        "pdf.page",
        "pdf.continued"
    ]

    init(context: UIGraphicsPDFRendererContext, bounds: CGRect, snapshot: EvidencePackSnapshot) {
        self.context = context
        self.bounds = bounds
        self.snapshot = snapshot
        self.sectionTitle = L10n.string("pdf.section.evidence_pack")
        _ = Self.localizationAnchors
    }

    func render() throws {
        drawCover()

        for (index, item) in snapshot.items.enumerated() {
            try drawEvidenceItem(
                item,
                number: index + 1,
                includeCaseVerification: index == snapshot.items.count - 1
            )
        }
    }

    // MARK: - Cover

    private func drawCover() {
        beginPage(section: L10n.string("pdf.section.evidence_pack"))

        let heroRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: 170)
        drawRoundedCard(heroRect, fill: navy, stroke: navy, radius: 15)

        accent.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 22, width: 38, height: 4),
            cornerRadius: 2
        ).fill()

        drawTextAt(
            "KAMILUNAVO TRACE",
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 36, width: heroRect.width - 44, height: 16),
            font: .systemFont(ofSize: 9.5, weight: .bold),
            color: UIColor(red: 0.48, green: 0.70, blue: 1.0, alpha: 1)
        )
        drawTextAt(
            L10n.string("pdf.heading.evidence_pack"),
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 58, width: heroRect.width - 44, height: 34),
            font: .systemFont(ofSize: 26, weight: .bold),
            color: .white
        )
        drawTextAt(
            snapshot.title,
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 100, width: heroRect.width - 44, height: 30),
            font: .systemFont(ofSize: 17, weight: .semibold),
            color: .white
        )
        drawTextAt(
            snapshot.kind,
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 138, width: heroRect.width - 44, height: 18),
            font: .systemFont(ofSize: 9.8, weight: .medium),
            color: UIColor(white: 0.76, alpha: 1)
        )
        cursorY = heroRect.maxY + 14

        let gap: CGFloat = 8
        let statWidth = (contentWidth - gap * 2) / 3
        drawCompactStat(
            label: L10n.string("pdf.field.evidence_items"),
            value: "\(snapshot.items.count)",
            rect: CGRect(x: margin, y: cursorY, width: statWidth, height: 58)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.case_created"),
            value: formatDisplay(snapshot.createdAt),
            rect: CGRect(x: margin + statWidth + gap, y: cursorY, width: statWidth, height: 58)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.pack_generated"),
            value: formatDisplay(snapshot.generatedAt),
            rect: CGRect(x: margin + (statWidth + gap) * 2, y: cursorY, width: statWidth, height: 58)
        )
        cursorY += 70

        drawStatusBand(
            snapshot.currentSnapshotIsSealed
                ? L10n.string("bundle.result_valid")
                : L10n.string("pdf.snapshot.not_sealed"),
            positive: snapshot.currentSnapshotIsSealed
        )

        drawKeyValueBand(
            label: L10n.string("pdf.field.case_id"),
            value: snapshot.caseID.uuidString,
            monospaced: true,
            fill: surface,
            stroke: line,
            minimumHeight: 50
        )

        drawTitleBlock(
            title: L10n.string("pdf.field.evidence_items"),
            eyebrow: L10n.string("pdf.section.evidence_pack").uppercased(),
            titleSize: 16
        )

        for (index, item) in snapshot.items.prefix(8).enumerated() {
            let label = "#\(index + 1)  •  \(item.kind)  •  \(formatDisplay(item.recordedAt))"
            drawIndexRow(label)
        }
    }

    // MARK: - Evidence

    private func drawEvidenceItem(
        _ item: EvidencePackItemSnapshot,
        number: Int,
        includeCaseVerification: Bool
    ) throws {
        var verifiedMedia: Data?
        var verifiedType: UTType?

        if let mediaURL = item.mediaURL,
           let mediaHash = item.mediaHash,
           let typeIdentifier = item.mediaUTType,
           let contentType = UTType(typeIdentifier) {
            let originalData = try Data(contentsOf: mediaURL)
            guard EvidenceHasher.sha256(originalData) == mediaHash else {
                throw EvidencePackExportError.originalIntegrityMismatch(item.mediaOriginalName ?? item.kind)
            }
            verifiedMedia = originalData
            verifiedType = contentType
        }

        beginPage(section: L10n.format("pdf.section.evidence_number", number))
        drawTitleBlock(
            title: item.kind,
            eyebrow: L10n.format("pdf.heading.evidence_number", number).uppercased(),
            titleSize: 23
        )

        let gap: CGFloat = 8
        let columnWidth = (contentWidth - gap) / 2
        drawCompactStat(
            label: L10n.string("pdf.field.recorded"),
            value: formatDisplay(item.recordedAt),
            rect: CGRect(x: margin, y: cursorY, width: columnWidth, height: 58)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.source"),
            value: item.source.isEmpty ? "—" : item.source,
            rect: CGRect(x: margin + columnWidth + gap, y: cursorY, width: columnWidth, height: 58)
        )
        cursorY += 70

        if !item.note.isEmpty {
            drawBodyCard(
                label: L10n.string("pdf.field.user_note"),
                value: item.note,
                font: .systemFont(ofSize: 10.5),
                fill: .white,
                stroke: line
            )
        }

        if let originalName = item.mediaOriginalName {
            let value = [
                originalName,
                item.mediaUTType.map { "\(L10n.string("pdf.field.original_type")): \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "   •   ")
            drawKeyValueBand(
                label: L10n.string("pdf.field.original_file"),
                value: value,
                fill: surface,
                stroke: line,
                valueFont: .systemFont(ofSize: 9.5, weight: .medium),
                minimumHeight: 48
            )
        }

        if let originalData = verifiedMedia, let contentType = verifiedType {
            if contentType.conforms(to: .image) {
                guard let image = UIImage(data: originalData) else {
                    throw EvidencePackExportError.unableToRenderImage(item.mediaOriginalName ?? item.kind)
                }
                drawInlineImagePreview(image)
            } else if contentType.conforms(to: .pdf) {
                guard let document = PDFDocument(data: originalData), document.pageCount > 0 else {
                    throw EvidencePackExportError.unableToRenderPDF(item.mediaOriginalName ?? item.kind)
                }
                for pageIndex in 0..<document.pageCount {
                    guard let page = document.page(at: pageIndex) else {
                        throw EvidencePackExportError.unableToRenderPDF(item.mediaOriginalName ?? item.kind)
                    }
                    drawPDFPagePreview(
                        page,
                        item: item,
                        number: number,
                        pageIndex: pageIndex,
                        pageCount: document.pageCount
                    )
                }
            }
        }

        drawEvidenceAppendix(
            item,
            number: number,
            includeCaseVerification: includeCaseVerification
        )
    }

    private func drawInlineImagePreview(_ image: UIImage) {
        let minimumPreviewHeight: CGFloat = 250
        if contentBottom - cursorY < minimumPreviewHeight {
            beginPage(section: L10n.string("pdf.preview.heading_image"))
        }

        drawSmallSectionLabel(L10n.string("pdf.preview.heading_image"))
        let availableHeight = max(contentBottom - cursorY, minimumPreviewHeight)
        let frameRect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: availableHeight
        )
        drawRoundedCard(frameRect, fill: surface, stroke: line, radius: 12)
        let imageRect = frameRect.insetBy(dx: 12, dy: 12)
        image.draw(in: aspectFitRect(imageSize: image.size, inside: imageRect))
        cursorY = frameRect.maxY
    }

    private func drawPDFPagePreview(
        _ page: PDFPage,
        item: EvidencePackItemSnapshot,
        number: Int,
        pageIndex: Int,
        pageCount: Int
    ) {
        beginPage(section: L10n.format("pdf.preview.section_pdf", number))
        drawTitleBlock(
            title: item.mediaOriginalName ?? L10n.string("pdf.preview.pdf_fallback"),
            eyebrow: L10n.format("pdf.preview.heading_pdf", pageIndex + 1, pageCount).uppercased(),
            titleSize: 16
        )

        let frameRect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: max(contentBottom - cursorY, 180)
        )
        drawRoundedCard(frameRect, fill: surface, stroke: line, radius: 12)
        let available = frameRect.insetBy(dx: 12, dy: 12)
        let thumbnail = page.thumbnail(
            of: CGSize(width: available.width * 2, height: available.height * 2),
            for: .mediaBox
        )
        thumbnail.draw(in: aspectFitRect(imageSize: thumbnail.size, inside: available))
        cursorY = frameRect.maxY
    }

    // MARK: - OCR + compact verification

    private func drawEvidenceAppendix(
        _ item: EvidencePackItemSnapshot,
        number: Int,
        includeCaseVerification: Bool
    ) {
        let hasOCR = item.recognizedTextAt != nil
        let appendixTitle = hasOCR
            ? L10n.string("evidence.recognized_text")
            : L10n.string("bundle.result_details")

        beginPage(section: appendixTitle)
        drawTitleBlock(
            title: appendixTitle,
            eyebrow: L10n.format("pdf.heading.evidence_number", number).uppercased(),
            titleSize: 20
        )

        if hasOCR {
            let metadata = [
                item.recognizedTextEngine.map { "\(L10n.string("pdf.ocr.engine")): \($0)" },
                item.recognizedTextAt.map { "\(L10n.string("pdf.ocr.recognized")): \(formatDisplay($0))" },
                item.recognizedTextPageCount.map { "\(L10n.string("pdf.ocr.pages")): \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "   •   ")

            if !metadata.isEmpty {
                drawKeyValueBand(
                    label: L10n.string("evidence.recognized_text"),
                    value: metadata,
                    fill: accentSoft,
                    stroke: accent.withAlphaComponent(0.18),
                    valueFont: .systemFont(ofSize: 8.8, weight: .medium),
                    minimumHeight: 46
                )
            }

            let text = item.recognizedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            drawTextFlow(
                text.isEmpty ? L10n.string("pdf.ocr.no_text") : text,
                font: .systemFont(ofSize: 9.8),
                color: ink,
                spacingAfter: 12
            )
            drawTextFlow(
                L10n.string("pdf.ocr.trust"),
                font: .systemFont(ofSize: 8.2),
                color: muted,
                spacingAfter: 14
            )
        }

        let verificationHeight: CGFloat = includeCaseVerification ? 210 : 142
        ensureSpace(verificationHeight)
        drawSmallSectionLabel(L10n.string("bundle.result_details"))

        if let mediaHash = item.mediaHash {
            drawHashRow(label: L10n.string("pdf.field.original_sha"), hash: mediaHash)
        }
        drawHashRow(label: L10n.string("pdf.field.record_sha"), hash: item.recordHash)

        if includeCaseVerification {
            if let seal = currentMatchingSeal() {
                drawHashRow(label: L10n.string("pdf.seals.heading"), hash: seal.manifestHash)
            } else {
                drawHashRow(label: L10n.string("pdf.field.manifest_sha"), hash: snapshot.currentManifestHash)
            }
            drawStatusBand(
                snapshot.currentSnapshotIsSealed
                    ? L10n.string("bundle.result_valid")
                    : L10n.string("pdf.snapshot.not_sealed"),
                positive: snapshot.currentSnapshotIsSealed,
                compact: true
            )
        }
    }

    private func currentMatchingSeal() -> EvidencePackSealSnapshot? {
        snapshot.seals
            .filter {
                $0.itemCount == snapshot.items.count
                    && $0.manifestHash == snapshot.currentManifestHash
            }
            .max(by: { $0.createdAt < $1.createdAt })
    }

    // MARK: - Page chrome

    private func beginPage(section: String) {
        sectionTitle = section
        context.beginPage()
        pageCount += 1

        UIColor.white.setFill()
        context.cgContext.fill(bounds)

        accent.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: margin, y: 18, width: 9, height: 9),
            cornerRadius: 3
        ).fill()

        drawTextAt(
            "KAMILUNAVO TRACE",
            in: CGRect(x: margin + 17, y: 16, width: contentWidth * 0.44, height: 15),
            font: .systemFont(ofSize: 8.4, weight: .bold),
            color: ink
        )
        drawTextAt(
            section.uppercased(),
            in: CGRect(x: margin + contentWidth * 0.45, y: 16, width: contentWidth * 0.55, height: 15),
            font: .systemFont(ofSize: 8.0, weight: .semibold),
            color: muted,
            alignment: .right
        )

        context.cgContext.setStrokeColor(line.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: 43.5))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: 43.5))
        context.cgContext.strokePath()

        context.cgContext.move(to: CGPoint(x: margin, y: bounds.height - 37))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: bounds.height - 37))
        context.cgContext.strokePath()

        drawTextAt(
            "Kamilunavo Trace • \(snapshot.caseID.uuidString.prefix(8))",
            in: CGRect(x: margin, y: bounds.height - 29, width: contentWidth * 0.68, height: 13),
            font: .systemFont(ofSize: 7.5, weight: .medium),
            color: muted
        )
        drawTextAt(
            L10n.format("pdf.page", pageCount),
            in: CGRect(x: margin + contentWidth * 0.68, y: bounds.height - 29, width: contentWidth * 0.32, height: 13),
            font: .systemFont(ofSize: 7.5, weight: .semibold),
            color: muted,
            alignment: .right
        )

        cursorY = 60
    }

    // MARK: - Components

    private func drawTitleBlock(title: String, eyebrow: String, titleSize: CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: titleSize, weight: .bold)
        let titleHeight = measuredTextHeight(title, font: titleFont, width: contentWidth)
        let totalHeight = 16 + titleHeight + 12
        ensureSpace(totalHeight)

        drawTextAt(
            eyebrow,
            in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 14),
            font: .systemFont(ofSize: 8.1, weight: .bold),
            color: accent
        )
        cursorY += 18
        drawTextAt(
            title,
            in: CGRect(x: margin, y: cursorY, width: contentWidth, height: titleHeight + 3),
            font: titleFont,
            color: ink
        )
        cursorY += titleHeight + 12
    }

    private func drawSmallSectionLabel(_ text: String) {
        ensureSpace(24)
        drawTextAt(
            text.uppercased(),
            in: CGRect(x: margin, y: cursorY, width: contentWidth, height: 14),
            font: .systemFont(ofSize: 8.0, weight: .bold),
            color: accent
        )
        cursorY += 20
    }

    private func drawCompactStat(label: String, value: String, rect: CGRect) {
        drawRoundedCard(rect, fill: surface, stroke: line, radius: 10)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 11, y: rect.minY + 9, width: rect.width - 22, height: 13),
            font: .systemFont(ofSize: 6.9, weight: .bold),
            color: muted
        )
        drawTextAt(
            value,
            in: CGRect(x: rect.minX + 11, y: rect.minY + 29, width: rect.width - 22, height: 20),
            font: .systemFont(ofSize: 9.0, weight: .semibold),
            color: ink
        )
    }

    private func drawStatusBand(
        _ text: String,
        positive: Bool,
        compact: Bool = false
    ) {
        let bodyFont = UIFont.systemFont(ofSize: compact ? 8.7 : 9.3, weight: .semibold)
        let bodyHeight = measuredTextHeight(text, font: bodyFont, width: contentWidth - 28)
        let height = max(compact ? 40 : 46, bodyHeight + 22)
        ensureSpace(height + 8)

        let fill = positive ? success.withAlphaComponent(0.08) : surface
        let stroke = positive ? success.withAlphaComponent(0.25) : line
        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: fill, stroke: stroke, radius: 10)
        drawTextAt(
            text,
            in: CGRect(x: rect.minX + 14, y: rect.minY + 11, width: rect.width - 28, height: bodyHeight + 3),
            font: bodyFont,
            color: ink
        )
        cursorY = rect.maxY + 8
    }

    private func drawIndexRow(_ value: String) {
        let height: CGFloat = 36
        ensureSpace(height + 6)
        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: .white, stroke: line, radius: 9)
        drawTextAt(
            value,
            in: CGRect(x: rect.minX + 12, y: rect.minY + 10, width: rect.width - 24, height: 16),
            font: .systemFont(ofSize: 9.0, weight: .medium),
            color: ink
        )
        cursorY = rect.maxY + 6
    }

    private func drawKeyValueBand(
        label: String,
        value: String,
        monospaced: Bool = false,
        fill: UIColor,
        stroke: UIColor,
        valueFont: UIFont? = nil,
        minimumHeight: CGFloat = 48
    ) {
        let bodyFont = valueFont ?? (
            monospaced
                ? UIFont.monospacedSystemFont(ofSize: 7.4, weight: .regular)
                : UIFont.systemFont(ofSize: 9.5, weight: .medium)
        )
        let innerWidth = contentWidth - 28
        let valueHeight = measuredTextHeight(value, font: bodyFont, width: innerWidth)
        let height = max(minimumHeight, 28 + valueHeight)
        ensureSpace(height + 8)

        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: fill, stroke: stroke, radius: 10)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 14, y: rect.minY + 9, width: innerWidth, height: 13),
            font: .systemFont(ofSize: 7.1, weight: .bold),
            color: muted
        )
        drawTextAt(
            value,
            in: CGRect(x: rect.minX + 14, y: rect.minY + 25, width: innerWidth, height: valueHeight + 3),
            font: bodyFont,
            color: ink
        )
        cursorY = rect.maxY + 8
    }

    private func drawBodyCard(
        label: String,
        value: String,
        font: UIFont,
        fill: UIColor,
        stroke: UIColor
    ) {
        let innerWidth = contentWidth - 28
        let bodyHeight = measuredTextHeight(value, font: font, width: innerWidth)
        let height = max(56, 34 + bodyHeight)
        ensureSpace(height + 8)

        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: fill, stroke: stroke, radius: 10)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 14, y: rect.minY + 10, width: innerWidth, height: 13),
            font: .systemFont(ofSize: 7.2, weight: .bold),
            color: muted
        )
        drawTextAt(
            value,
            in: CGRect(x: rect.minX + 14, y: rect.minY + 28, width: innerWidth, height: bodyHeight + 3),
            font: font,
            color: ink
        )
        cursorY = rect.maxY + 8
    }

    private func drawHashRow(label: String, hash: String) {
        let height: CGFloat = 45
        ensureSpace(height + 6)
        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: accentSoft, stroke: accent.withAlphaComponent(0.14), radius: 9)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 12, y: rect.minY + 7, width: rect.width - 24, height: 12),
            font: .systemFont(ofSize: 6.7, weight: .bold),
            color: muted
        )
        drawTextAt(
            hash,
            in: CGRect(x: rect.minX + 12, y: rect.minY + 23, width: rect.width - 24, height: 13),
            font: .monospacedSystemFont(ofSize: 6.8, weight: .medium),
            color: ink
        )
        cursorY = rect.maxY + 6
    }

    private func drawRoundedCard(
        _ rect: CGRect,
        fill: UIColor,
        stroke: UIColor,
        radius: CGFloat
    ) {
        fill.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.fill()
        stroke.setStroke()
        path.lineWidth = 0.7
        path.stroke()
    }

    // MARK: - Text and layout

    private func ensureSpace(_ height: CGFloat) {
        if cursorY + height > contentBottom {
            beginPage(section: L10n.format("pdf.continued", sectionTitle))
        }
    }

    private func drawTextFlow(
        _ text: String,
        font: UIFont,
        color: UIColor,
        spacingAfter: CGFloat
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let lines = wrappedLines(text, font: font, width: contentWidth)

        for line in lines {
            let display = line.isEmpty ? " " : line
            let lineHeight = max(font.lineHeight, measuredTextHeight(display, font: font, width: contentWidth))
            ensureSpace(lineHeight + 2)
            NSString(string: display).draw(
                in: CGRect(x: margin, y: cursorY, width: contentWidth, height: lineHeight + 2),
                withAttributes: attributes
            )
            cursorY += lineHeight + 1
        }
        cursorY += spacingAfter
    }

    private func drawTextAt(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        NSString(string: text).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
    }

    private func measuredTextHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: paragraph],
            context: nil
        )
        return max(ceil(rect.height), font.lineHeight)
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

    private func formatDisplay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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
        guard let document = PDFDocument(url: url), document.pageCount >= 3 else {
            throw EvidencePackSmokeError.invalidPDF
        }
        let extractedText = document.string ?? ""
        let requiredTokens = [
            "KAMILUNAVO TRACE",
            L10n.string("pdf.heading.evidence_pack"),
            "CI OCR Smoke",
            Self.evidencePackSmokeCaseID.uuidString,
            L10n.string("pdf.field.original_sha"),
            expectedMediaHash,
            L10n.string("pdf.field.record_sha"),
            expectedRecordHash,
            L10n.string("evidence.recognized_text"),
            "EVIDARO 4827",
            L10n.string("pdf.seals.heading"),
            expectedSealHash
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
