import Foundation

@main
struct OfflineQueueModelRegression {
    static func main() {
        let requestID = UUID(uuidString: "11111111-1111-4111-8111-111111111111")!

        let request = SourceIngestionRequest(
            kind: .pdf,
            title: "Elternbrief",
            text: nil,
            fileData: Data([0x01, 0x02, 0x03]),
            fileName: "Elternbrief.pdf",
            contentType: "application/pdf",
            extractedText: "Elternabend am Freitag",
            clientRequestID: requestID
        )

        precondition(request.clientRequestID == requestID, "source request must preserve stable idempotency id")

        let local = InboxSource(
            id: requestID,
            title: request.title,
            kind: request.kind,
            createdAt: Date(timeIntervalSince1970: 1_787_000_000),
            status: .queued,
            proposalCount: 0,
            sourceText: request.extractedText,
            errorMessage: "Lokal gespeichert",
            contentType: request.contentType,
            fileName: request.fileName,
            sizeBytes: request.fileData?.count,
            clientRequestID: requestID,
            isLocalOnly: true
        )

        precondition(local.id == requestID, "local queue row must use the stable request id")
        precondition(local.clientRequestID == requestID, "local queue row must expose the stable request id")
        precondition(local.isLocalOnly, "queued local source must stay distinguishable from canonical backend rows")
        precondition(local.status == .queued, "queued local source must render as queued")

        let server = InboxSource(
            id: UUID(),
            title: "Server source",
            kind: .text,
            createdAt: .now,
            status: .review,
            proposalCount: 1,
            sourceText: "Test",
            errorMessage: nil
        )

        precondition(server.clientRequestID == nil, "existing server models must remain backward compatible")
        precondition(!server.isLocalOnly, "existing server models must not become local-only by default")

        print("Offline queue model regression passed")
    }
}
