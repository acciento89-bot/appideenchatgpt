import Foundation
@main struct PDFPageBreakTests {
 static func main() {
  let a = "Previous paragraph.\n\nVersion 1 · 2026-10-23T09:58:33Z\n\nRecorded work."
  let maximum=(a as NSString).range(of:"2026").location
  let split=PDFPageBreak.preferredLength(in:a, maximumUTF16Length:maximum)
  precondition(!(a as NSString).substring(to:split).contains("Version 1"), "A short revision header must not split from its timestamp")
  let b="Earlier details.\n\nAktueller Inhalt nicht bestätigt.\n\nFurther information."
  let bound=(b as NSString).range(of:"bestätigt").location
  let bSplit=PDFPageBreak.preferredLength(in:b,maximumUTF16Length:bound)
  precondition(!(b as NSString).substring(to:bSplit).contains("Aktueller Inhalt"), "A fitting short paragraph must move intact")
  let c="Earlier details.\n\nGESPEICHERTE VERSIONEN\n\nVersion 1 · date\n\nWork."
  let cBound=(c as NSString).range(of:" · date").location
  let cSplit=PDFPageBreak.preferredLength(in:c,maximumUTF16Length:cBound)
  precondition(!(c as NSString).substring(to:cSplit).contains("GESPEICHERTE VERSIONEN"), "A section heading must stay with its content")
  precondition(PDFPageBreak.preferredLength(in:"No paragraph break, a long text",maximumUTF16Length:12)==12,"Long paragraph must still progress")
  precondition(PDFPageBreak.preferredLength(in:"",maximumUTF16Length:10)==0)
  precondition(PDFPageBreak.preferredLength(in:"All fits",maximumUTF16Length:100)==8)
  let unicode="😀abc";let u=PDFPageBreak.preferredLength(in:unicode,maximumUTF16Length:1)
  precondition((unicode as NSString).substring(to:u)=="😀", "Never split a surrogate or composed character")
  var rest=a;var reconstructed="";var pages=0
  while !rest.isEmpty { let length=PDFPageBreak.preferredLength(in:rest,maximumUTF16Length:20);precondition(length>0);let source=rest as NSString;reconstructed+=source.substring(to:length);rest=source.substring(from:length);pages+=1;precondition(pages<100) }
  precondition(reconstructed==a,"No dropped or duplicated text")
  print("PASS native PDF page boundaries: intact paragraphs, attached headers, Unicode and exact reconstruction")
 }
}
