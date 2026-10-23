import Foundation

/// Refines an already measured UTF-16 fit without changing or discarding report text.
enum PDFPageBreak {
    static func preferredLength(in text: String, maximumUTF16Length: Int) -> Int {
        let source = text as NSString
        let limit = min(source.length, max(0, maximumUTF16Length))
        guard limit > 0, limit < source.length else { return limit }
        let newline = source.rangeOfCharacter(from: .newlines, options: .backwards,
                                             range: NSRange(location: 0, length: limit))
        var boundary = newline.location == NSNotFound ? 0 : NSMaxRange(newline)
        // Prefer complete paragraphs. Keep section/revision headings with the first body paragraph.
        while boundary > 0 {
            let prefix = source.substring(to: boundary).trimmingCharacters(in: .whitespacesAndNewlines) as NSString
            guard prefix.length > 0 else { boundary = 0; break }
            let previous = prefix.rangeOfCharacter(from: .newlines, options: .backwards)
            let start = previous.location == NSNotFound ? 0 : NSMaxRange(previous)
            let line = prefix.substring(from: start).trimmingCharacters(in: .whitespacesAndNewlines)
            let heading = ["GESPEICHERTE VERSIONEN", "SAVED REVISIONS"].contains(line)
                || line.range(of: "^(Version|Revision) [0-9]+ ·", options: .regularExpression) != nil
            guard heading else { return boundary }
            boundary = start
        }
        // A paragraph longer than one page still advances at the measured word boundary.
        // If that boundary touches a composed character, retain the complete character.
        let character = source.rangeOfComposedCharacterSequence(at: limit - 1)
        guard NSMaxRange(character) > limit else { return limit }
        return character.location > 0 ? character.location : NSMaxRange(character)
    }
}
