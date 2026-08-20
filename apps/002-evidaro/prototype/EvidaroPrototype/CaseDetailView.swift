import SwiftUI

struct CaseDetailView: View {
    @ObservedObject var store: EvidenceStore
    let caseID: UUID

    @State private var showsAddEvidence = false
    @State private var latestSeal: EvidenceSeal?

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
                .alert("Snapshot sealed", isPresented: Binding(
                    get: { latestSeal != nil },
                    set: { if !$0 { latestSeal = nil } }
                )) {
                    Button("OK", role: .cancel) { latestSeal = nil }
                } message: {
                    if let latestSeal {
                        Text("\(latestSeal.itemCount) evidence item(s) are represented by manifest hash \(latestSeal.manifestHash.prefix(12))…")
                    }
                }
            } else {
                ContentUnavailableView("Case unavailable", systemImage: "exclamationmark.triangle")
            }
        }
    }

    private func caseHeader(_ evidenceCase: EvidenceCase) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: evidenceCase.kind.symbol)
                .font(.title2.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(evidenceCase.kind.rawValue)
                    .font(.subheadline.bold())
                Text("Created \(evidenceCase.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Case ID \(evidenceCase.id.uuidString.prefix(8))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func actionRow(_ evidenceCase: EvidenceCase) -> some View {
        VStack(spacing: 10) {
            Button {
                showsAddEvidence = true
            } label: {
                Label("Add evidence", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 10) {
                Button {
                    latestSeal = store.seal(caseID: caseID)
                } label: {
                    Label("Seal snapshot", systemImage: "checkmark.seal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(evidenceCase.evidence.isEmpty)

                ShareLink(item: store.shareManifest(caseID: caseID)) {
                    Label("Share manifest", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(evidenceCase.evidence.isEmpty)
            }
        }
    }

    private func timeline(_ evidenceCase: EvidenceCase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Evidence timeline")
                .font(.title3.bold())

            if evidenceCase.evidence.isEmpty {
                ContentUnavailableView(
                    "No evidence yet",
                    systemImage: "paperclip",
                    description: Text("Add the first factual note while the details are fresh.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(evidenceCase.evidence.sorted(by: { $0.recordedAt > $1.recordedAt })) { item in
                    EvidenceRow(item: item)
                }
            }
        }
    }

    private func seals(_ evidenceCase: EvidenceCase) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Snapshot seals")
                    .font(.title3.bold())
                Spacer()
                Text("\(evidenceCase.seals.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.thinMaterial, in: Capsule())
            }

            if evidenceCase.seals.isEmpty {
                Text("No sealed snapshot yet. A seal records the current evidence-item hash list without preventing later additions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(evidenceCase.seals.reversed()) { seal in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Label("\(seal.itemCount) item snapshot", systemImage: "checkmark.seal.fill")
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
                    }
                    .padding(15)
                    .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }
}

private struct EvidenceRow: View {
    let item: EvidenceItem

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: item.kind.symbol)
                .font(.subheadline.bold())
                .frame(width: 38, height: 38)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.kind.rawValue)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(item.recordedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !item.source.isEmpty {
                    Text(item.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(item.note)
                    .font(.body)

                HStack(spacing: 5) {
                    Image(systemName: "number")
                    Text(item.contentHash)
                        .lineLimit(1)
                }
                .font(.caption2.monospaced())
                .foregroundStyle(.tertiary)
                .textSelection(.enabled)
            }
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
