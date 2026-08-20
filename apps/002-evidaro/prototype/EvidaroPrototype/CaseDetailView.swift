import SwiftUI
import UIKit

struct CaseDetailView: View {
    @ObservedObject var store: EvidenceStore
    let caseID: UUID

    @State private var showsAddEvidence = false
    @State private var latestSeal: EvidenceSeal?
    @State private var isGeneratingEvidencePack = false
    @State private var evidencePackShareItem: EvidencePackShareItem?
    @State private var evidencePackError: String?

    var body: some View {
        Group {
            if let evidenceCase = store.caseForID(caseID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        caseHeader(evidenceCase)
                        actionRow(evidenceCase)
                        timeline(evidenceCase)
                        seals(evidenceCase)
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
                .navigationTitle(evidenceCase.title)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showsAddEvidence) {
                    AddEvidenceView(store: store, caseID: caseID)
                }
                .sheet(item: $evidencePackShareItem) { shareItem in
                    EvidencePackShareSheet(url: shareItem.url)
                        .ignoresSafeArea()
                }
                .alert("snapshot.sealed_title", isPresented: Binding(
                    get: { latestSeal != nil },
                    set: { if !$0 { latestSeal = nil } }
                )) {
                    Button("common.ok", role: .cancel) { latestSeal = nil }
                } message: {
                    if let latestSeal {
                        Text(
                            L10n.format(
                                "snapshot.sealed_message",
                                latestSeal.itemCount,
                                String(latestSeal.manifestHash.prefix(12))
                            )
                        )
                    }
                }
                .alert("pdf.export_failed", isPresented: Binding(
                    get: { evidencePackError != nil },
                    set: { if !$0 { evidencePackError = nil } }
                )) {
                    Button("common.ok", role: .cancel) { evidencePackError = nil }
                } message: {
                    if let evidencePackError {
                        Text(evidencePackError)
                    }
                }
            } else {
                ContentUnavailableView("case.unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func caseHeader(_ evidenceCase: EvidenceCase) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: evidenceCase.kind.symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(evidenceCase.kind.localizedName)
                    .font(.subheadline.bold())
                Text(
                    L10n.format(
                        "case.created",
                        evidenceCase.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                Text(L10n.format("case.id", String(evidenceCase.id.uuidString.prefix(8))))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 8)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func actionRow(_ evidenceCase: EvidenceCase) -> some View {
        VStack(spacing: 10) {
            Button {
                showsAddEvidence = true
            } label: {
                Label("evidence.add", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    sealButton(evidenceCase)
                    shareManifestButton(evidenceCase)
                }

                VStack(spacing: 10) {
                    sealButton(evidenceCase)
                    shareManifestButton(evidenceCase)
                }
            }

            Button {
                generateEvidencePack()
            } label: {
                HStack(spacing: 8) {
                    if isGeneratingEvidencePack {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Label(
                        isGeneratingEvidencePack ? L10n.string("pdf.building") : L10n.string("pdf.build_share"),
                        systemImage: "doc.richtext"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(evidenceCase.evidence.isEmpty || isGeneratingEvidencePack)
        }
    }

    private func sealButton(_ evidenceCase: EvidenceCase) -> some View {
        Button {
            latestSeal = store.seal(caseID: caseID)
        } label: {
            Label("snapshot.seal", systemImage: "checkmark.seal")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(evidenceCase.evidence.isEmpty)
    }

    private func shareManifestButton(_ evidenceCase: EvidenceCase) -> some View {
        ShareLink(item: store.shareManifest(caseID: caseID)) {
            Label("snapshot.share_manifest", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(evidenceCase.evidence.isEmpty)
    }

    private func timeline(_ evidenceCase: EvidenceCase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("evidence.timeline")
                .font(.title3.bold())
                .accessibilityHeading(.h2)

            if evidenceCase.evidence.isEmpty {
                ContentUnavailableView(
                    "evidence.empty.title",
                    systemImage: "paperclip",
                    description: Text("evidence.empty.description")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(evidenceCase.evidence.sorted(by: { $0.recordedAt > $1.recordedAt })) { item in
                    EvidenceRow(store: store, caseID: evidenceCase.id, item: item)
                }
            }
        }
    }

    private func seals(_ evidenceCase: EvidenceCase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("snapshot.seals")
                    .font(.title3.bold())
                    .accessibilityHeading(.h2)
                Spacer()
                Text("\(evidenceCase.seals.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if evidenceCase.seals.isEmpty {
                Text("snapshot.none")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(evidenceCase.seals.sorted(by: { $0.createdAt > $1.createdAt })) { seal in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Label(
                                L10n.format("snapshot.item", seal.itemCount),
                                systemImage: "checkmark.seal.fill"
                            )
                            .font(.subheadline.bold())
                            Spacer()
                            Text(seal.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(seal.manifestHash)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .accessibilityLabel(L10n.string("accessibility.hash_record"))
                            .accessibilityValue(seal.manifestHash)
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }

    private func generateEvidencePack() {
        guard !isGeneratingEvidencePack else { return }
        isGeneratingEvidencePack = true
        evidencePackError = nil

        Task {
            defer { isGeneratingEvidencePack = false }
            do {
                let result = try await store.generateEvidencePack(caseID: caseID)
                evidencePackShareItem = EvidencePackShareItem(url: result.url)
            } catch {
                evidencePackError = error.localizedDescription
            }
        }
    }
}

private struct EvidenceRow: View {
    @ObservedObject var store: EvidenceStore
    let caseID: UUID
    let item: EvidenceItem

    @State private var isRecognizingText = false
    @State private var recognitionError: String?

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: item.kind.symbol)
                .font(.subheadline.bold())
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Text(item.kind.localizedName)
                        .font(.subheadline.bold())
                    Spacer(minLength: 8)
                    Text(item.recordedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !item.source.isEmpty {
                    Text(item.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.body)
                }

                if let originalName = item.mediaOriginalName,
                   let mediaHash = item.mediaHash {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Label(originalName, systemImage: "paperclip")
                                .font(.caption.bold())
                                .lineLimit(1)
                            Spacer(minLength: 8)
                            if let mediaURL = store.mediaURL(for: item) {
                                ShareLink(item: mediaURL) {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("evidence.share_original"))
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("evidence.original_sha")
                            Text(mediaHash)
                                .textSelection(.enabled)
                        }
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(L10n.string("accessibility.hash_original"))
                        .accessibilityValue(mediaHash)
                    }
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if store.canRecognizeText(for: item) {
                    recognizedTextSection
                }

                HStack(spacing: 5) {
                    Image(systemName: "number")
                        .accessibilityHidden(true)
                    Text("evidence.record_sha")
                    Text(item.contentHash)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.string("accessibility.hash_record"))
                .accessibilityValue(item.contentHash)
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var recognizedTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label("evidence.recognized_text", systemImage: "text.viewfinder")
                    .font(.caption.bold())
                Spacer(minLength: 8)
                if isRecognizingText {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button(item.hasRecognizedTextResult ? L10n.string("evidence.refresh") : L10n.string("evidence.recognize")) {
                        runRecognition()
                    }
                    .font(.caption.bold())
                    .buttonStyle(.borderless)
                }
            }

            if item.hasRecognizedTextResult {
                if let text = item.recognizedText, !text.isEmpty {
                    Text(text)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("evidence.no_text")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    if let pageCount = item.recognizedTextPageCount {
                        Text(pageCount == 1 ? L10n.string("evidence.one_page") : L10n.format("evidence.pages", pageCount))
                    }
                    if let recognizedAt = item.recognizedTextAt {
                        Text("•")
                            .accessibilityHidden(true)
                        Text(recognizedAt, style: .relative)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            if let recognitionError {
                Text(recognitionError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("evidence.ocr_trust")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func runRecognition() {
        guard !isRecognizingText else { return }
        isRecognizingText = true
        recognitionError = nil

        Task {
            defer { isRecognizingText = false }
            do {
                try await store.recognizeText(caseID: caseID, itemID: item.id)
            } catch {
                recognitionError = error.localizedDescription
            }
        }
    }
}

private struct EvidencePackShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct EvidencePackShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
