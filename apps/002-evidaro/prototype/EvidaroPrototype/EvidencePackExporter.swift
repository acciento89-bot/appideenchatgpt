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

    private var contentWidth: CGFloat { bounds.width - (margin * 2) }
    private var contentBottom: CGFloat { bounds.height - margin - footerHeight }

    private let accent = UIColor(red: 0.10, green: 0.36, blue: 0.88, alpha: 1)
    private let accentSoft = UIColor(red: 0.93, green: 0.96, blue: 1.0, alpha: 1)
    private let navy = UIColor(red: 0.055, green: 0.075, blue: 0.13, alpha: 1)
    private let ink = UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
    private let muted = UIColor(red: 0.39, green: 0.42, blue: 0.48, alpha: 1)
    private let line = UIColor(red: 0.86, green: 0.88, blue: 0.91, alpha: 1)
    private let surface = UIColor(red: 0.965, green: 0.97, blue: 0.98, alpha: 1)
    private let success = UIColor(red: 0.09, green: 0.53, blue: 0.34, alpha: 1)

    init(context: UIGraphicsPDFRendererContext, bounds: CGRect, snapshot: EvidencePackSnapshot) {
        self.context = context
        self.bounds = bounds
        self.snapshot = snapshot
        self.sectionTitle = L10n.string("pdf.section.evidence_pack")
    }

    func render() throws {
        drawCover()

        for (index, item) in snapshot.items.enumerated() {
            try drawEvidenceItem(item, number: index + 1)
        }

        drawSealHistory()
    }

    private func drawCover() {
        beginPage(section: L10n.string("pdf.section.evidence_pack"))

        let heroRect = CGRect(x: margin, y: cursorY, width: contentWidth, height: 214)
        drawRoundedCard(heroRect, fill: navy, stroke: navy)

        accent.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 24, width: 38, height: 5),
            cornerRadius: 2.5
        ).fill()

        drawTextAt(
            "KAMILUNAVO TRACE",
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 40, width: heroRect.width - 44, height: 18),
            font: .systemFont(ofSize: 10.5, weight: .bold),
            color: UIColor(red: 0.45, green: 0.68, blue: 1.0, alpha: 1)
        )
        drawTextAt(
            L10n.string("pdf.heading.evidence_pack"),
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 66, width: heroRect.width - 44, height: 42),
            font: .systemFont(ofSize: 29, weight: .bold),
            color: .white
        )
        drawTextAt(
            snapshot.title,
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 118, width: heroRect.width - 44, height: 48),
            font: .systemFont(ofSize: 20, weight: .semibold),
            color: .white
        )
        drawTextAt(
            snapshot.kind,
            in: CGRect(x: heroRect.minX + 22, y: heroRect.minY + 171, width: heroRect.width * 0.58, height: 20),
            font: .systemFont(ofSize: 11, weight: .medium),
            color: UIColor(white: 0.78, alpha: 1)
        )

        let coverState = snapshot.currentSnapshotIsSealed
            ? L10n.string("pdf.snapshot.matches")
            : L10n.string("pdf.snapshot.not_sealed")
        drawPill(
            coverState,
            x: heroRect.maxX - 178,
            y: heroRect.minY + 169,
            width: 156,
            fill: snapshot.currentSnapshotIsSealed ? success.withAlphaComponent(0.18) : UIColor.white.withAlphaComponent(0.10),
            textColor: snapshot.currentSnapshotIsSealed ? UIColor(red: 0.48, green: 0.95, blue: 0.72, alpha: 1) : .white
        )
        cursorY = heroRect.maxY + 18

        let gap: CGFloat = 10
        let cardWidth = (contentWidth - gap * 2) / 3
        drawCompactStat(
            label: L10n.string("pdf.field.evidence_items"),
            value: "\(snapshot.items.count)",
            rect: CGRect(x: margin, y: cursorY, width: cardWidth, height: 72)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.case_created"),
            value: formatShort(snapshot.createdAt),
            rect: CGRect(x: margin + cardWidth + gap, y: cursorY, width: cardWidth, height: 72)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.pack_generated"),
            value: formatShort(snapshot.generatedAt),
            rect: CGRect(x: margin + (cardWidth + gap) * 2, y: cursorY, width: cardWidth, height: 72)
        )
        cursorY += 86

        drawBlockCard(
            label: L10n.string("pdf.field.case_id"),
            value: snapshot.caseID.uuidString,
            monospaced: true,
            fill: surface
        )
        drawHashCard(
            label: L10n.string("pdf.field.manifest_sha"),
            hash: snapshot.currentManifestHash
        )

        ensureSpace(184)
        drawSectionHeading(
            L10n.string("pdf.integrity_model"),
            eyebrow: L10n.string("pdf.section.evidence_pack").uppercased()
        )
        let integrityText = [
            L10n.string("pdf.integrity.originals"),
            L10n.string("pdf.integrity.previews"),
            L10n.string("pdf.integrity.ocr"),
            L10n.string("pdf.integrity.legal")
        ].joined(separator: "\n\n")
        drawBlockCard(
            label: L10n.string("pdf.integrity_model"),
            value: integrityText,
            fill: UIColor.white,
            stroke: line,
            valueFont: .systemFont(ofSize: 10.2)
        )
    }

    private func drawEvidenceItem(_ item: EvidencePackItemSnapshot, number: Int) throws {
        beginPage(section: L10n.format("pdf.section.evidence_number", number))
        drawSectionHeading(
            item.kind,
            eyebrow: L10n.format("pdf.heading.evidence_number", number).uppercased()
        )

        let gap: CGFloat = 10
        let cardWidth = (contentWidth - gap) / 2
        drawCompactStat(
            label: L10n.string("pdf.field.recorded"),
            value: format(item.recordedAt),
            rect: CGRect(x: margin, y: cursorY, width: cardWidth, height: 74)
        )
        drawCompactStat(
            label: L10n.string("pdf.field.source"),
            value: item.source.isEmpty ? "—" : item.source,
            rect: CGRect(x: margin + cardWidth + gap, y: cursorY, width: cardWidth, height: 74)
        )
        cursorY += 88

        if !item.note.isEmpty {
            drawBlockCard(
                label: L10n.string("pdf.field.user_note"),
                value: item.note,
                fill: UIColor.white,
                stroke: line,
                valueFont: .systemFont(ofSize: 11)
            )
        }

        if let originalName = item.mediaOriginalName {
            let fileDescription = [
                originalName,
                item.mediaUTType.map { "\(L10n.string("pdf.field.original_type")): \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "\n")
            drawBlockCard(
                label: L10n.string("pdf.field.original_file"),
                value: fileDescription,
                fill: surface,
                valueFont: .systemFont(ofSize: 10.5)
            )
        } else if let mediaType = item.mediaUTType {
            drawBlockCard(
                label: L10n.string("pdf.field.original_type"),
                value: mediaType,
                fill: surface,
                valueFont: .systemFont(ofSize: 10.5)
            )
        }

        if let mediaHash = item.mediaHash {
            drawHashCard(label: L10n.string("pdf.field.original_sha"), hash: mediaHash)
        }
        drawHashCard(label: L10n.string("pdf.field.record_sha"), hash: item.recordHash)

        if item.recognizedTextAt != nil {
            ensureSpace(156)
            drawSectionHeading(
                L10n.string("pdf.ocr.heading"),
                eyebrow: L10n.string("pdf.ocr.heading").uppercased()
            )

            let metadata = [
                item.recognizedTextEngine.map { "\(L10n.string("pdf.ocr.engine")): \($0)" },
                item.recognizedTextAt.map { "\(L10n.string("pdf.ocr.recognized")): \(format($0))" },
                item.recognizedTextPageCount.map { "\(L10n.string("pdf.ocr.pages")): \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "   •   ")

            if !metadata.isEmpty {
                drawBlockCard(
                    label: L10n.string("pdf.ocr.heading"),
                    value: metadata,
                    fill: accentSoft,
                    stroke: accent.withAlphaComponent(0.18),
                    valueFont: .systemFont(ofSize: 9.6, weight: .medium)
                )
            }

            let text = item.recognizedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            drawBlockCard(
                label: L10n.string("pdf.ocr.heading"),
                value: text.isEmpty ? L10n.string("pdf.ocr.no_text") : text,
                fill: UIColor.white,
                stroke: line,
                valueFont: .systemFont(ofSize: 10.5)
            )
            drawText(
                L10n.string("pdf.ocr.trust"),
                font: .systemFont(ofSize: 9.3),
                color: muted,
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

    private func drawImagePreview(_ image: UIImage, item: EvidencePackItemSnapshot, number: Int) {
        beginPage(section: L10n.format("pdf.preview.section_image", number))
        drawSectionHeading(
            item.mediaOriginalName ?? L10n.string("pdf.preview.image_fallback"),
            eyebrow: L10n.string("pdf.preview.heading_image").uppercased()
        )

        let captionHeight: CGFloat = 76
        let frameRect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: max(contentBottom - cursorY - captionHeight - 12, 120)
        )
        drawRoundedCard(frameRect, fill: surface, stroke: line, radius: 14)
        let imageRect = frameRect.insetBy(dx: 12, dy: 12)
        image.draw(in: aspectFitRect(imageSize: image.size, inside: imageRect))
        cursorY = frameRect.maxY + 10

        drawBlockCard(
            label: L10n.string("pdf.preview.image_hash_note"),
            value: item.mediaHash ?? "",
            monospaced: true,
            fill: accentSoft,
            stroke: accent.withAlphaComponent(0.18),
            valueFont: .monospacedSystemFont(ofSize: 7.8, weight: .regular)
        )
    }

    private func drawPDFPagePreview(
        _ page: PDFPage,
        item: EvidencePackItemSnapshot,
        number: Int,
        pageIndex: Int,
        pageCount: Int
    ) {
        beginPage(section: L10n.format("pdf.preview.section_pdf", number))
        drawSectionHeading(
            item.mediaOriginalName ?? L10n.string("pdf.preview.pdf_fallback"),
            eyebrow: L10n.format("pdf.preview.heading_pdf", pageIndex + 1, pageCount).uppercased()
        )

        let captionHeight: CGFloat = 76
        let frameRect = CGRect(
            x: margin,
            y: cursorY,
            width: contentWidth,
            height: max(contentBottom - cursorY - captionHeight - 12, 120)
        )
        drawRoundedCard(frameRect, fill: surface, stroke: line, radius: 14)
        let available = frameRect.insetBy(dx: 12, dy: 12)
        let thumbnail = page.thumbnail(
            of: CGSize(width: available.width * 2, height: available.height * 2),
            for: .mediaBox
        )
        thumbnail.draw(in: aspectFitRect(imageSize: thumbnail.size, inside: available))
        cursorY = frameRect.maxY + 10

        drawBlockCard(
            label: L10n.string("pdf.preview.pdf_hash_note"),
            value: item.mediaHash ?? "",
            monospaced: true,
            fill: accentSoft,
            stroke: accent.withAlphaComponent(0.18),
            valueFont: .monospacedSystemFont(ofSize: 7.8, weight: .regular)
        )
    }

    private func drawSealHistory() {
        beginPage(section: L10n.string("pdf.seals.section"))
        drawSectionHeading(
            L10n.string("pdf.seals.heading"),
            eyebrow: L10n.string("pdf.seals.section").uppercased()
        )
        drawText(
            L10n.string("pdf.seals.explanation"),
            font: .systemFont(ofSize: 10.5),
            color: muted,
            spacingAfter: 16
        )

        if snapshot.seals.isEmpty {
            drawBlockCard(
                label: L10n.string("pdf.seals.heading"),
                value: L10n.string("pdf.seals.none"),
                fill: surface
            )
        } else {
            for (index, seal) in snapshot.seals.sorted(by: { $0.createdAt > $1.createdAt }).enumerated() {
                let isCurrent = seal.itemCount == snapshot.items.count
                    && seal.manifestHash == snapshot.currentManifestHash
                drawSealCard(
                    seal,
                    label: L10n.format("pdf.seals.label", snapshot.seals.count - index),
                    state: isCurrent ? L10n.string("pdf.seals.current") : L10n.string("pdf.seals.historical"),
                    isCurrent: isCurrent
                )
            }
        }

        ensureSpace(150)
        drawSectionHeading(
            L10n.string("pdf.field.manifest_sha"),
            eyebrow: L10n.string("pdf.field.snapshot_status").uppercased()
        )
        drawHashCard(label: L10n.string("pdf.field.manifest_sha"), hash: snapshot.currentManifestHash)
        drawBlockCard(
            label: L10n.string("pdf.field.snapshot_status"),
            value: snapshot.currentSnapshotIsSealed
                ? L10n.string("pdf.seals.current_matches")
                : L10n.string("pdf.seals.current_not_sealed"),
            fill: snapshot.currentSnapshotIsSealed ? success.withAlphaComponent(0.08) : surface,
            stroke: snapshot.currentSnapshotIsSealed ? success.withAlphaComponent(0.24) : line,
            valueFont: .systemFont(ofSize: 10.5, weight: .semibold)
        )
        drawText(
            L10n.string("pdf.seals.legal"),
            font: .systemFont(ofSize: 9.3),
            color: muted,
            spacingAfter: 0
        )
    }

    private func beginPage(section: String) {
        sectionTitle = section
        context.beginPage()
        pageCount += 1
        UIColor.white.setFill()
        context.cgContext.fill(bounds)

        let topBand = CGRect(x: 0, y: 0, width: bounds.width, height: 44)
        UIColor(red: 0.985, green: 0.988, blue: 0.995, alpha: 1).setFill()
        context.cgContext.fill(topBand)

        accent.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: margin, y: 18, width: 10, height: 10),
            cornerRadius: 3
        ).fill()

        drawTextAt(
            "KAMILUNAVO TRACE",
            in: CGRect(x: margin + 18, y: 16.5, width: contentWidth * 0.44, height: 16),
            font: .systemFont(ofSize: 8.6, weight: .bold),
            color: ink
        )

        let sectionParagraph = NSMutableParagraphStyle()
        sectionParagraph.alignment = .right
        let sectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.3, weight: .semibold),
            .foregroundColor: muted,
            .paragraphStyle: sectionParagraph
        ]
        NSString(string: section.uppercased()).draw(
            in: CGRect(x: margin + contentWidth * 0.45, y: 17, width: contentWidth * 0.55, height: 16),
            withAttributes: sectionAttributes
        )

        context.cgContext.setStrokeColor(line.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: 43.5))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: 43.5))
        context.cgContext.strokePath()
        cursorY = 60

        context.cgContext.setStrokeColor(line.cgColor)
        context.cgContext.setLineWidth(0.6)
        context.cgContext.move(to: CGPoint(x: margin, y: bounds.height - 37))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: bounds.height - 37))
        context.cgContext.strokePath()

        drawTextAt(
            "Kamilunavo Trace • \(snapshot.caseID.uuidString.prefix(8))",
            in: CGRect(x: margin, y: bounds.height - 29, width: contentWidth * 0.68, height: 14),
            font: .systemFont(ofSize: 7.8, weight: .medium),
            color: muted
        )

        let pageParagraph = NSMutableParagraphStyle()
        pageParagraph.alignment = .right
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.8, weight: .semibold),
            .foregroundColor: muted,
            .paragraphStyle: pageParagraph
        ]
        NSString(string: L10n.format("pdf.page", pageCount)).draw(
            in: CGRect(
                x: margin + contentWidth * 0.68,
                y: bounds.height - 29,
                width: contentWidth * 0.32,
                height: 14
            ),
            withAttributes: pageAttributes
        )
    }

    private func drawSectionHeading(_ title: String, eyebrow: String) {
        ensureSpace(62)
        drawText(
            eyebrow,
            font: .systemFont(ofSize: 8.7, weight: .bold),
            color: accent,
            spacingAfter: 5
        )
        drawText(
            title,
            font: .systemFont(ofSize: 22, weight: .bold),
            color: ink,
            spacingAfter: 14
        )
    }

    private func drawCompactStat(label: String, value: String, rect: CGRect) {
        drawRoundedCard(rect, fill: surface, stroke: line, radius: 12)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 12, y: rect.minY + 12, width: rect.width - 24, height: 16),
            font: .systemFont(ofSize: 7.5, weight: .bold),
            color: muted
        )
        drawTextAt(
            value,
            in: CGRect(x: rect.minX + 12, y: rect.minY + 34, width: rect.width - 24, height: 26),
            font: .systemFont(ofSize: 10.2, weight: .semibold),
            color: ink
        )
    }

    private func drawBlockCard(
        label: String,
        value: String,
        monospaced: Bool = false,
        fill: UIColor,
        stroke: UIColor = UIColor.clear,
        valueFont: UIFont? = nil
    ) {
        let labelFont = UIFont.systemFont(ofSize: 8.2, weight: .bold)
        let bodyFont = valueFont ?? (
            monospaced
                ? UIFont.monospacedSystemFont(ofSize: 8.2, weight: .regular)
                : UIFont.systemFont(ofSize: 10.5)
        )
        let innerWidth = contentWidth - 28
        let bodyHeight = measuredTextHeight(value, font: bodyFont, width: innerWidth)
        let height = max(64, 40 + bodyHeight)
        ensureSpace(height + 10)

        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(rect, fill: fill, stroke: stroke, radius: 12)
        drawTextAt(
            label.uppercased(),
            in: CGRect(x: rect.minX + 14, y: rect.minY + 12, width: innerWidth, height: 15),
            font: labelFont,
            color: muted
        )
        drawTextAt(
            value,
            in: CGRect(
                x: rect.minX + 14,
                y: rect.minY + 32,
                width: innerWidth,
                height: max(bodyHeight + 4, 22)
            ),
            font: bodyFont,
            color: ink
        )
        cursorY = rect.maxY + 10
    }

    private func drawHashCard(label: String, hash: String) {
        drawBlockCard(
            label: label,
            value: hash,
            monospaced: true,
            fill: accentSoft,
            stroke: accent.withAlphaComponent(0.16),
            valueFont: .monospacedSystemFont(ofSize: 8.0, weight: .medium)
        )
    }

    private func drawSealCard(
        _ seal: EvidencePackSealSnapshot,
        label: String,
        state: String,
        isCurrent: Bool
    ) {
        let height: CGFloat = 118
        ensureSpace(height + 12)
        let rect = CGRect(x: margin, y: cursorY, width: contentWidth, height: height)
        drawRoundedCard(
            rect,
            fill: UIColor.white,
            stroke: isCurrent ? success.withAlphaComponent(0.30) : line,
            radius: 13
        )

        drawTextAt(
            label,
            in: CGRect(x: rect.minX + 14, y: rect.minY + 13, width: rect.width * 0.55, height: 18),
            font: .systemFont(ofSize: 11, weight: .bold),
            color: ink
        )
        drawPill(
            state,
            x: rect.maxX - 130,
            y: rect.minY + 10,
            width: 116,
            fill: isCurrent ? success.withAlphaComponent(0.10) : surface,
            textColor: isCurrent ? success : muted
        )

        drawTextAt(
            "\(L10n.string("pdf.field.recorded")): \(format(seal.createdAt))",
            in: CGRect(x: rect.minX + 14, y: rect.minY + 40, width: rect.width - 28, height: 16),
            font: .systemFont(ofSize: 8.8, weight: .medium),
            color: muted
        )
        drawTextAt(
            "\(L10n.string("pdf.field.item_count")): \(seal.itemCount)",
            in: CGRect(x: rect.minX + 14, y: rect.minY + 59, width: rect.width - 28, height: 16),
            font: .systemFont(ofSize: 8.8, weight: .medium),
            color: muted
        )
        drawTextAt(
            L10n.string("pdf.field.seal_manifest_sha").uppercased(),
            in: CGRect(x: rect.minX + 14, y: rect.minY + 79, width: rect.width - 28, height: 13),
            font: .systemFont(ofSize: 7.2, weight: .bold),
            color: muted
        )
        drawTextAt(
            seal.manifestHash,
            in: CGRect(x: rect.minX + 14, y: rect.minY + 95, width: rect.width - 28, height: 15),
            font: .monospacedSystemFont(ofSize: 7.3, weight: .regular),
            color: ink
        )
        cursorY = rect.maxY + 12
    }

    private func drawPill(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        fill: UIColor,
        textColor: UIColor
    ) {
        let rect = CGRect(x: x, y: y, width: width, height: 24)
        fill.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.8, weight: .bold),
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        NSString(string: text).draw(
            in: CGRect(x: rect.minX + 6, y: rect.minY + 6, width: rect.width - 12, height: 14),
            withAttributes: attributes
        )
    }

    private func drawRoundedCard(
        _ rect: CGRect,
        fill: UIColor,
        stroke: UIColor,
        radius: CGFloat = 12
    ) {
        fill.setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        path.fill()
        stroke.setStroke()
        path.lineWidth = 0.7
        path.stroke()
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

    private func ensureSpace(_ height: CGFloat) {
        if cursorY + height > contentBottom {
            beginPage(section: L10n.format("pdf.continued", sectionTitle))
        }
    }

    private func drawText(
        _ text: String,
        font: UIFont,
        color: UIColor = .black,
        spacingAfter: CGFloat = 8
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let lines = wrappedLines(text, font: font, width: contentWidth)

        for lineText in lines {
            let display = lineText.isEmpty ? " " : lineText
            let measured = NSString(string: display).boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            let lineHeight = max(ceil(measured.height), font.lineHeight)
            ensureSpace(lineHeight + 1)
            NSString(string: display).draw(
                in: CGRect(x: margin, y: cursorY, width: contentWidth, height: lineHeight + 2),
                withAttributes: attributes
            )
            cursorY += lineHeight + 1
        }
        cursorY += spacingAfter
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

    private func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        return formatter.string(from: date)
    }

    private func formatShort(_ date: Date) -> String {
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
        guard let document = PDFDocument(url: url), document.pageCount >= 4 else {
            throw EvidencePackSmokeError.invalidPDF
        }
        let extractedText = document.string ?? ""
        let legalText = L10n.string("pdf.integrity.legal")
        let legalMarker = legalText.components(separatedBy: ".").first ?? legalText
        let requiredTokens = [
            "KAMILUNAVO TRACE",
            L10n.string("pdf.heading.evidence_pack"),
            "CI OCR Smoke",
            Self.evidencePackSmokeCaseID.uuidString,
            L10n.string("pdf.field.original_sha"),
            expectedMediaHash,
            L10n.string("pdf.field.record_sha"),
            expectedRecordHash,
            L10n.string("pdf.ocr.heading"),
            "EVIDARO 4827",
            L10n.string("pdf.seals.heading"),
            expectedSealHash,
            legalMarker
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
