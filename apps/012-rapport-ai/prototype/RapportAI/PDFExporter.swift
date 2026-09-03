import UIKit

enum PDFExporter {
    static func makePDF(for report: RapportDraft, profile: CompanyProfile) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Rapport-\(report.id.uuidString.prefix(8)).pdf")

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            let margin: CGFloat = 48
            var y: CGFloat = 46

            if let data = profile.logoData, let image = UIImage(data: data) {
                image.draw(in: CGRect(x: margin, y: y - 8, width: 62, height: 62))
            }
            let titleX = profile.logoData == nil ? margin : margin + 76
            draw("ARBEITSRAPPORT", at: CGRect(x: titleX, y: y, width: 300, height: 28), font: .boldSystemFont(ofSize: 22), color: UIColor(red: 0.05, green: 0.42, blue: 0.62, alpha: 1))
            draw(profile.hasIdentity ? profile.companyName : "RAPPORT AI", at: CGRect(x: 365, y: y + 3, width: 180, height: 22), font: .boldSystemFont(ofSize: 10), color: .darkGray, alignment: .right)
            y += 48

            let companyLine = [profile.ownerName, profile.address, profile.phone, profile.email]
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .joined(separator: " · ")
            if !companyLine.isEmpty {
                draw(companyLine, at: CGRect(x: margin, y: y, width: page.width - margin * 2, height: 34), font: .systemFont(ofSize: 8), color: .gray)
                y += 34
            }

            let details = [
                ("Gewerk", report.trade.title),
                ("Kunde", report.customer),
                ("Einsatzort", report.location),
                ("Anlage", report.system),
                ("Datum", report.createdAt.formatted(date: .long, time: .shortened))
            ].filter { !$0.1.isEmpty }

            for detail in details {
                draw(detail.0.uppercased(), at: CGRect(x: margin, y: y, width: 110, height: 20), font: .boldSystemFont(ofSize: 9), color: .gray)
                draw(detail.1, at: CGRect(x: margin + 115, y: y - 1, width: 380, height: 22), font: .systemFont(ofSize: 11), color: .black)
                y += 23
            }
            y += 22

            draw(report.reportText, at: CGRect(x: margin, y: y, width: page.width - margin * 2, height: page.height - y - 85), font: .systemFont(ofSize: 12), color: .black)
            draw("Vor Verwendung fachlich prüfen.", at: CGRect(x: margin, y: page.height - 48, width: page.width - margin * 2, height: 18), font: .italicSystemFont(ofSize: 9), color: .gray)
        }
        return url
    }

    private static func draw(_ text: String, at rect: CGRect, font: UIFont, color: UIColor, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = 4
        (text as NSString).draw(in: rect, withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
    }
}
