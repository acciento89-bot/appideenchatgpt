from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
PACK = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype/EvidencePackExporter.swift"
PREFLIGHT = ROOT / "apps/002-evidaro/ci/public_identity_preflight.py"
PROJECT = ROOT / "apps/002-evidaro/prototype/EvidaroPrototype.xcodeproj/project.pbxproj"

pack = PACK.read_text()

legacy_cover = '        drawText("EVIDARO", font: .systemFont(ofSize: 14, weight: .bold), color: .darkGray, spacingAfter: 7)\n        drawText(L10n.string("pdf.heading.evidence_pack"), font: .systemFont(ofSize: 29, weight: .bold), spacingAfter: 12)\n        drawText(snapshot.title, font: .systemFont(ofSize: 22, weight: .semibold), spacingAfter: 4)\n        drawText(snapshot.kind, font: .systemFont(ofSize: 13, weight: .medium), color: .darkGray, spacingAfter: 20)\n\n        drawRule()'
new_cover = '''        let heroTop = cursorY
        let heroHeight: CGFloat = 170
        let heroRect = CGRect(x: margin, y: heroTop, width: contentWidth, height: heroHeight)
        UIColor(white: 0.965, alpha: 1).setFill()
        UIBezierPath(roundedRect: heroRect, cornerRadius: 18).fill()

        let accent = UIColor(red: 0.18, green: 0.47, blue: 0.96, alpha: 1)
        accent.setFill()
        UIBezierPath(
            roundedRect: CGRect(x: heroRect.minX, y: heroRect.minY, width: 6, height: heroRect.height),
            cornerRadius: 3
        ).fill()

        cursorY = heroTop + 22
        drawText("KAMILUNAVO TRACE", font: .systemFont(ofSize: 10.5, weight: .bold), color: accent, spacingAfter: 8)
        drawText(L10n.string("pdf.heading.evidence_pack"), font: .systemFont(ofSize: 30, weight: .bold), spacingAfter: 10)
        drawText(snapshot.title, font: .systemFont(ofSize: 21, weight: .semibold), spacingAfter: 4)
        drawText(snapshot.kind, font: .systemFont(ofSize: 12.5, weight: .medium), color: .darkGray, spacingAfter: 0)
        cursorY = heroRect.maxY + 24

        drawRule()'''
if legacy_cover not in pack:
    raise SystemExit("expected legacy PDF cover block not found")
pack = pack.replace(legacy_cover, new_cover, 1)

legacy_page = '''    private func beginPage(section: String) {
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
        NSString(string: "EVIDARO • \\(section.uppercased())").draw(
            in: CGRect(x: margin, y: 20, width: contentWidth, height: 16),
            withAttributes: headerAttributes
        )

        let footer = "Evidaro • \\(snapshot.caseID.uuidString.prefix(8)) • \\(L10n.format(\"pdf.page\", pageCount))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.darkGray
        ]
        NSString(string: footer).draw(
            in: CGRect(x: margin, y: bounds.height - 31, width: contentWidth, height: 14),
            withAttributes: footerAttributes
        )
    }'''
new_page = '''    private func beginPage(section: String) {
        sectionTitle = section
        context.beginPage()
        pageCount += 1
        UIColor.white.setFill()
        context.cgContext.fill(bounds)

        let accent = UIColor(red: 0.18, green: 0.47, blue: 0.96, alpha: 1)
        let headerBrandAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .bold),
            .foregroundColor: accent
        ]
        NSString(string: "KAMILUNAVO TRACE").draw(
            in: CGRect(x: margin, y: 19, width: contentWidth * 0.48, height: 16),
            withAttributes: headerBrandAttributes
        )

        let sectionParagraph = NSMutableParagraphStyle()
        sectionParagraph.alignment = .right
        let headerSectionAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8.5, weight: .semibold),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: sectionParagraph
        ]
        NSString(string: section.uppercased()).draw(
            in: CGRect(x: margin + contentWidth * 0.48, y: 19, width: contentWidth * 0.52, height: 16),
            withAttributes: headerSectionAttributes
        )

        context.cgContext.setStrokeColor(accent.withAlphaComponent(0.35).cgColor)
        context.cgContext.setLineWidth(0.8)
        context.cgContext.move(to: CGPoint(x: margin, y: 39))
        context.cgContext.addLine(to: CGPoint(x: bounds.width - margin, y: 39))
        context.cgContext.strokePath()
        cursorY = margin + 10

        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.darkGray
        ]
        NSString(string: "Kamilunavo Trace • \\(snapshot.caseID.uuidString.prefix(8))").draw(
            in: CGRect(x: margin, y: bounds.height - 31, width: contentWidth * 0.68, height: 14),
            withAttributes: footerAttributes
        )
        let footerParagraph = NSMutableParagraphStyle()
        footerParagraph.alignment = .right
        let pageAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: footerParagraph
        ]
        NSString(string: L10n.format("pdf.page", pageCount)).draw(
            in: CGRect(x: margin + contentWidth * 0.68, y: bounds.height - 31, width: contentWidth * 0.32, height: 14),
            withAttributes: pageAttributes
        )
    }'''
if legacy_page not in pack:
    raise SystemExit("expected legacy PDF page chrome block not found")
pack = pack.replace(legacy_page, new_page, 1)

legacy_smoke = '''        let requiredTokens = [
            "EVIDARO",
            L10n.string("pdf.heading.evidence_pack"),'''
new_smoke = '''        let requiredTokens = [
            "KAMILUNAVO TRACE",
            L10n.string("pdf.heading.evidence_pack"),'''
if legacy_smoke not in pack:
    raise SystemExit("expected legacy PDF smoke brand token not found")
pack = pack.replace(legacy_smoke, new_smoke, 1)

PACK.write_text(pack)

preflight = PREFLIGHT.read_text()
needle = '"Trace PDF smoke filename": \'Kamilunavo-Trace-\' in APP_ENTRY,\n'
addition = '''"Trace PDF smoke filename": 'Kamilunavo-Trace-' in APP_ENTRY,
"legacy PDF cover brand retired": 'drawText("EVIDARO"' not in PACK,
"legacy PDF page header retired": 'NSString(string: "EVIDARO •' not in PACK,
"legacy PDF footer retired": 'let footer = "Evidaro •' not in PACK,
'''
if needle not in preflight:
    raise SystemExit("public identity preflight anchor not found")
preflight = preflight.replace(needle, addition, 1)
PREFLIGHT.write_text(preflight)

project = PROJECT.read_text()
count = project.count("CURRENT_PROJECT_VERSION = 2;")
if count != 2:
    raise SystemExit(f"expected two Build 2 project settings, found {count}")
project = project.replace("CURRENT_PROJECT_VERSION = 2;", "CURRENT_PROJECT_VERSION = 3;")
PROJECT.write_text(project)

print("Applied Trace PDF release fix: public branding, page chrome, cover hero, regression guards and Build 3.")
