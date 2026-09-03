import UIKit

enum PDFExporter {
    private enum Layout {
        static let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        static let margin: CGFloat = 42
        static let contentWidth = page.width - margin * 2
        static let headerHeight: CGFloat = 110
        static let footerTop: CGFloat = 804
        static let signatureTop: CGFloat = 682
        static let firstBodyTop: CGFloat = 326
        static let continuedBodyTop: CGFloat = 158
    }

    private enum Palette {
        static let navy = UIColor(red: 0.025, green: 0.105, blue: 0.145, alpha: 1)
        static let blue = UIColor(red: 0.025, green: 0.34, blue: 0.50, alpha: 1)
        static let cyan = UIColor(red: 0.00, green: 0.68, blue: 0.89, alpha: 1)
        static let orange = UIColor(red: 1.00, green: 0.45, blue: 0.04, alpha: 1)
        static let ink = UIColor(red: 0.08, green: 0.12, blue: 0.16, alpha: 1)
        static let muted = UIColor(red: 0.38, green: 0.44, blue: 0.49, alpha: 1)
        static let line = UIColor(red: 0.84, green: 0.87, blue: 0.89, alpha: 1)
        static let panel = UIColor(red: 0.965, green: 0.975, blue: 0.98, alpha: 1)
    }

    private struct TextPage {
        let range: NSRange
        let isFirst: Bool
        let isFinal: Bool
    }

    static func makePDF(for report: RapportDraft, profile: CompanyProfile) throws -> URL {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Arbeitsrapport \(rapportNumber(for: report))",
            kCGPDFContextAuthor as String: companyName(profile),
            kCGPDFContextCreator as String: "Rapport AI"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: Layout.page, format: format)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Rapport-\(report.id.uuidString.prefix(8)).pdf")
        let body = report.reportText.trimmingCharacters(in: .whitespacesAndNewlines)
        let pages = paginate(body)

        try renderer.writePDF(to: url) { context in
            for (index, textPage) in pages.enumerated() {
                context.beginPage()
                drawHeader(report: report, profile: profile)

                if textPage.isFirst {
                    drawDetails(report: report)
                    drawSectionTitle("AUSGEFÜHRTE ARBEITEN", y: 286)
                } else {
                    drawSectionTitle("AUSGEFÜHRTE ARBEITEN - FORTSETZUNG", y: 126)
                }

                let bodyTop = textPage.isFirst ? Layout.firstBodyTop : Layout.continuedBodyTop
                drawBody(body, range: textPage.range, y: bodyTop)
                if textPage.isFinal { drawSignatures() }
                drawFooter(profile: profile, page: index + 1, pageCount: pages.count)
            }
        }
        return url
    }

    private static func drawHeader(report: RapportDraft, profile: CompanyProfile) {
        Palette.navy.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: Layout.page.width, height: Layout.headerHeight)).fill()
        Palette.orange.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: Layout.page.width, height: 7)).fill()

        var titleX = Layout.margin
        if let data = profile.logoData, let image = UIImage(data: data) {
            let tile = CGRect(x: Layout.margin, y: 24, width: 62, height: 62)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: tile, cornerRadius: 8).fill()
            image.draw(in: aspectFitRect(for: image.size, inside: tile.insetBy(dx: 6, dy: 6)))
            titleX = tile.maxX + 16
        }

        draw("ARBEITSRAPPORT", at: CGRect(x: titleX, y: 31, width: 275, height: 30), font: .systemFont(ofSize: 23, weight: .bold), color: .white, spacing: 0)
        draw(rapportNumber(for: report), at: CGRect(x: titleX, y: 65, width: 260, height: 16), font: .monospacedSystemFont(ofSize: 9, weight: .semibold), color: Palette.cyan, spacing: 0)

        let companyRect = CGRect(x: 360, y: 25, width: 193, height: 68)
        draw(companyName(profile).uppercased(), at: CGRect(x: companyRect.minX, y: companyRect.minY, width: companyRect.width, height: 18), font: .systemFont(ofSize: 10.5, weight: .bold), color: .white, alignment: .right, spacing: 1)
        let contact = [profile.ownerName, profile.address, profile.phone, profile.email]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        if !contact.isEmpty {
            draw(contact, at: CGRect(x: companyRect.minX, y: companyRect.minY + 22, width: companyRect.width, height: 48), font: .systemFont(ofSize: 7.5), color: UIColor(white: 0.82, alpha: 1), alignment: .right, spacing: 1.5)
        }
    }

    private static func drawDetails(report: RapportDraft) {
        let panel = CGRect(x: Layout.margin, y: 132, width: Layout.contentWidth, height: 132)
        Palette.panel.setFill()
        UIBezierPath(roundedRect: panel, cornerRadius: 10).fill()
        Palette.blue.setFill()
        UIBezierPath(roundedRect: CGRect(x: panel.minX, y: panel.minY, width: 5, height: panel.height), cornerRadius: 2.5).fill()

        let leftX = panel.minX + 22
        let rightX = panel.midX + 14
        let columnWidth = panel.width / 2 - 38
        drawField(label: "KUNDE / AUFTRAGGEBER", value: valueOrDash(report.customer), x: leftX, y: 148, width: columnWidth)
        drawField(label: "EINSATZORT", value: valueOrDash(report.location), x: leftX, y: 188, width: columnWidth)
        drawField(label: "GEWERK", value: report.trade.title, x: leftX, y: 228, width: columnWidth)
        drawField(label: "ANLAGE / BAUTEIL", value: valueOrDash(report.system), x: rightX, y: 148, width: columnWidth)
        drawField(label: "ERSTELLT AM", value: formattedDate(report.createdAt), x: rightX, y: 188, width: columnWidth)
        drawField(label: "RAPPORT-NR.", value: rapportNumber(for: report), x: rightX, y: 228, width: columnWidth)
    }

    private static func drawField(label: String, value: String, x: CGFloat, y: CGFloat, width: CGFloat) {
        draw(label, at: CGRect(x: x, y: y, width: width, height: 12), font: .systemFont(ofSize: 7.5, weight: .bold), color: Palette.muted, spacing: 0)
        draw(value, at: CGRect(x: x, y: y + 13, width: width, height: 22), font: .systemFont(ofSize: 10.5, weight: .medium), color: Palette.ink, spacing: 1)
    }

    private static func drawSectionTitle(_ title: String, y: CGFloat) {
        Palette.cyan.setFill()
        UIBezierPath(roundedRect: CGRect(x: Layout.margin, y: y, width: 5, height: 22), cornerRadius: 2.5).fill()
        draw(title, at: CGRect(x: Layout.margin + 15, y: y + 2, width: Layout.contentWidth - 15, height: 18), font: .systemFont(ofSize: 10, weight: .bold), color: Palette.blue, spacing: 0)
        Palette.line.setStroke()
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: Layout.margin + 15, y: y + 25))
        divider.addLine(to: CGPoint(x: Layout.page.width - Layout.margin, y: y + 25))
        divider.lineWidth = 0.6
        divider.stroke()
    }

    private static func drawBody(_ body: String, range: NSRange, y: CGFloat) {
        guard range.length > 0 else {
            draw("-", at: CGRect(x: Layout.margin + 15, y: y, width: Layout.contentWidth - 15, height: 20), font: bodyFont, color: Palette.ink)
            return
        }
        let text = (body as NSString).substring(with: range)
        NSAttributedString(string: text, attributes: bodyAttributes).draw(
            with: CGRect(x: Layout.margin + 15, y: y, width: Layout.contentWidth - 15, height: Layout.footerTop - 18 - y),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
    }

    private static func drawSignatures() {
        draw("BESTÄTIGUNG", at: CGRect(x: Layout.margin, y: Layout.signatureTop, width: Layout.contentWidth, height: 15), font: .systemFont(ofSize: 8, weight: .bold), color: Palette.muted, spacing: 0)
        let gap: CGFloat = 34
        let width = (Layout.contentWidth - gap) / 2
        let lineY = Layout.signatureTop + 58
        Palette.line.setStroke()
        for x in [Layout.margin, Layout.margin + width + gap] {
            let line = UIBezierPath()
            line.move(to: CGPoint(x: x, y: lineY))
            line.addLine(to: CGPoint(x: x + width, y: lineY))
            line.lineWidth = 0.8
            line.stroke()
        }
        draw("Ort, Datum / ausführender Betrieb", at: CGRect(x: Layout.margin, y: lineY + 7, width: width, height: 14), font: .systemFont(ofSize: 7.5), color: Palette.muted, spacing: 0)
        draw("Unterschrift Auftraggeber / Kunde", at: CGRect(x: Layout.margin + width + gap, y: lineY + 7, width: width, height: 14), font: .systemFont(ofSize: 7.5), color: Palette.muted, spacing: 0)
    }

    private static func drawFooter(profile: CompanyProfile, page: Int, pageCount: Int) {
        Palette.line.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: Layout.margin, y: Layout.footerTop))
        line.addLine(to: CGPoint(x: Layout.page.width - Layout.margin, y: Layout.footerTop))
        line.lineWidth = 0.6
        line.stroke()
        draw("\(companyName(profile)) | Digital erstellter Arbeitsrapport", at: CGRect(x: Layout.margin, y: Layout.footerTop + 8, width: 370, height: 11), font: .systemFont(ofSize: 7), color: Palette.muted, spacing: 0)
        draw("Seite \(page) von \(pageCount)", at: CGRect(x: 445, y: Layout.footerTop + 8, width: 108, height: 11), font: .monospacedSystemFont(ofSize: 7, weight: .medium), color: Palette.muted, alignment: .right, spacing: 0)
        draw("Inhalt und Messwerte vor Weitergabe fachlich prüfen.", at: CGRect(x: Layout.margin, y: Layout.footerTop + 21, width: Layout.contentWidth, height: 10), font: .italicSystemFont(ofSize: 6.5), color: UIColor(white: 0.58, alpha: 1), spacing: 0)
    }

    private static func paginate(_ body: String) -> [TextPage] {
        let source = body as NSString
        guard source.length > 0 else { return [TextPage(range: NSRange(location: 0, length: 0), isFirst: true, isFinal: true)] }
        var result: [TextPage] = []
        var offset = 0
        var pageIndex = 0
        while offset < source.length {
            let isFirst = pageIndex == 0
            let top = isFirst ? Layout.firstBodyTop : Layout.continuedBodyTop
            let remaining = source.length - offset
            let reservedLength = fittingLength(in: source.substring(from: offset), height: Layout.signatureTop - 28 - top)
            if reservedLength >= remaining {
                result.append(TextPage(range: NSRange(location: offset, length: remaining), isFirst: isFirst, isFinal: true))
                break
            }
            let fullLength = fittingLength(in: source.substring(from: offset), height: Layout.footerTop - 18 - top)
            let selectedLength = fullLength >= remaining ? reservedLength : fullLength
            let safeLength = max(1, selectedLength)
            result.append(TextPage(range: NSRange(location: offset, length: safeLength), isFirst: isFirst, isFinal: false))
            offset += safeLength
            while offset < source.length && CharacterSet.whitespacesAndNewlines.characterIsMember(source.character(at: offset)) { offset += 1 }
            pageIndex += 1
        }
        return result
    }

    private static func fittingLength(in text: String, height: CGFloat) -> Int {
        let source = text as NSString
        guard source.length > 0, height > 0 else { return 0 }
        let width = Layout.contentWidth - 15
        var low = 1
        var high = source.length
        var best = 0
        while low <= high {
            let middle = (low + high) / 2
            let size = (source.substring(to: middle) as NSString).boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: bodyAttributes,
                context: nil
            )
            if ceil(size.height) <= height { best = middle; low = middle + 1 } else { high = middle - 1 }
        }
        guard best < source.length else { return best }
        let breakRange = source.rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards, range: NSRange(location: 0, length: best))
        return breakRange.location == NSNotFound || breakRange.location == 0 ? best : breakRange.location
    }

    private static var bodyFont: UIFont { .systemFont(ofSize: 11.5) }

    private static var bodyAttributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4.5
        paragraph.paragraphSpacing = 8
        paragraph.lineBreakMode = .byWordWrapping
        return [.font: bodyFont, .foregroundColor: Palette.ink, .paragraphStyle: paragraph]
    }

    private static func rapportNumber(for report: RapportDraft) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "yyyyMMdd"
        return "RA-\(formatter.string(from: report.createdAt))-\(report.id.uuidString.prefix(6).uppercased())"
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "dd.MM.yyyy, HH:mm 'Uhr'"
        return formatter.string(from: date)
    }

    private static func companyName(_ profile: CompanyProfile) -> String {
        let name = profile.companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Rapport AI" : name
    }

    private static func valueOrDash(_ value: String) -> String {
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "-" : cleaned
    }

    private static func aspectFitRect(for imageSize: CGSize, inside bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return bounds }
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2, width: size.width, height: size.height)
    }

    private static func draw(_ text: String, at rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left, spacing: CGFloat = 3) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = spacing
        paragraph.lineBreakMode = .byWordWrapping
        (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
    }
}
