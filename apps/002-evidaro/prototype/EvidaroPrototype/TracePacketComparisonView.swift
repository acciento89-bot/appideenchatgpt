import SwiftUI
import UniformTypeIdentifiers

struct TracePacketComparisonView: View {
    private enum Slot { case baseline, candidate }
    @ObservedObject private var entitlement = EntitlementStore.shared
    @Environment(\.locale) private var locale
    @State private var baseline: TraceVerifiedPacket?
    @State private var candidate: TraceVerifiedPacket?
    @State private var comparison: TracePacketComparison?
    @State private var showsImporter = false
    @State private var slot: Slot = .baseline
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showsPro = false
    @State private var importTask: Task<Void, Never>?
    @State private var verificationTask: Task<TraceVerifiedPacket, Error>?
    private var german: Bool { locale.language.languageCode?.identifier == "de" }

    var body: some View {
        List {
            Section {
                Text("comparison.intro")
                Text("comparison.directionNote").font(.footnote).foregroundStyle(.secondary)
            }
            Section("comparison.baseline") { packetSlot(baseline, slot: .baseline) }
            Section("comparison.candidate") { packetSlot(candidate, slot: .candidate) }
            Section {
                Button("comparison.swap", systemImage: "arrow.up.arrow.down") { swap() }
                    .disabled(baseline == nil || candidate == nil || isLoading)
                if isLoading {
                    HStack { ProgressView(); Text("comparison.loading") }
                }
                Text("comparison.limits").font(.caption).foregroundStyle(.secondary)
            }
            if let comparison {
                Section("comparison.summary") {
                    count("comparison.unchanged", comparison.unchangedCount)
                    count("comparison.added", comparison.records.filter { $0.kind == .added }.count)
                    count("comparison.removed", comparison.records.filter { $0.kind == .removed }.count)
                    count("comparison.modified", comparison.records.filter { $0.kind == .modified }.count)
                    count("comparison.metadataOnly", comparison.records.filter { $0.kind == .metadataOnly }.count)
                    count("comparison.sealChanges", comparison.seals.count)
                    count("comparison.caseChanges", comparison.caseFields.count)
                }
                if !comparison.caseFields.isEmpty {
                    Section("comparison.caseChanges") { fieldChanges(comparison.caseFields) }
                }
                ForEach(comparison.records) { change in
                    Section {
                        Text(change.id).font(.caption.monospaced()).textSelection(.enabled)
                        fieldChanges(change.fields)
                    } header: { Text(TracePacketComparison.kindName(change.kind, german: german)) }
                }
                ForEach(comparison.seals) { change in
                    Section {
                        Text(TracePacketComparison.kindName(change.kind, german: german, snapshot: true)).font(.headline)
                        Text(change.id).font(.caption.monospaced()).textSelection(.enabled)
                        fieldChanges(change.fields)
                    } header: { Text("comparison.snapshotRecord") }
                }
                Section("comparison.report") {
                    if entitlement.isPro {
                        ShareLink(item: comparison.report(german: german)) {
                            Label("comparison.share", systemImage: "square.and.arrow.up")
                        }
                        DisclosureGroup("comparison.fullReport") {
                            Text(comparison.report(german: german)).font(.footnote).textSelection(.enabled)
                        }
                    } else {
                        Button { showsPro = true } label: {
                            Label("comparison.sharePro", systemImage: "lock.doc")
                        }
                        Text("comparison.proHint").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            Section("comparison.boundaryTitle") { Text("comparison.boundary").font(.footnote) }
        }
        .navigationTitle("comparison.title")
        .navigationBarTitleDisplayMode(.inline)
        .privacySensitive()
        .sheet(isPresented: $showsPro) { ProUpgradeView(entitlement: entitlement) }
        .fileImporter(isPresented: $showsImporter, allowedContentTypes: [.data], allowsMultipleSelection: false, onCompletion: importPacket)
        .alert("comparison.errorTitle", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("common.ok", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .onDisappear {
            importTask?.cancel(); verificationTask?.cancel()
        }
    }

    @ViewBuilder private func packetSlot(_ packet: TraceVerifiedPacket?, slot: Slot) -> some View {
        if let packet {
            Text(packet.sourceName).font(.headline)
            Text(packet.title)
            Label("comparison.checksPassed", systemImage: "checkmark.shield").font(.footnote)
            DisclosureGroup("comparison.packetDetails") {
                Text(packet.caseID).font(.caption.monospaced()).textSelection(.enabled)
                Text("comparison.packetHash").font(.caption.bold())
                Text(packet.bundleHash).font(.caption.monospaced()).textSelection(.enabled)
                Text("comparison.manifestHash").font(.caption.bold())
                Text(packet.manifestHash).font(.caption.monospaced()).textSelection(.enabled)
                count("comparison.items", packet.items.count)
                count("comparison.verifiedSeals", packet.verifiedSealCount)
            }
        } else { Text("comparison.notSelected").foregroundStyle(.secondary) }
        Button {
            self.slot = slot; showsImporter = true
        } label: {
            Label(packet == nil ? L10n.string("comparison.select") : L10n.string("comparison.replace"), systemImage: "doc.badge.plus")
        }.disabled(isLoading)
        if packet != nil {
            Button("comparison.clear", role: .destructive) {
                if slot == .baseline { baseline = nil } else { candidate = nil }
                comparison = nil
            }.disabled(isLoading)
        }
    }
    private func count(_ title: LocalizedStringKey, _ number: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(number.formatted()).monospacedDigit()
        }
    }
    @ViewBuilder private func fieldChanges(_ changes: [TraceFieldChange]) -> some View {
        ForEach(changes, id: \.key) { field in
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStringKey("comparison.field." + field.key)).font(.headline)
                Text(TracePacketComparison.categoryName(field.category, german: german))
                    .font(.caption).foregroundStyle(.secondary)
                Text("comparison.before").font(.caption.bold())
                Text(field.before ?? L10n.string("comparison.absent")).textSelection(.enabled)
                Text("comparison.after").font(.caption.bold())
                Text(field.after ?? L10n.string("comparison.absent")).textSelection(.enabled)
            }.padding(.vertical, 5)
        }
    }
    private func swap() {
        guard let baseline, let candidate else { return }
        do {
            let reversed = try TracePacketComparison.compare(baseline: candidate, candidate: baseline)
            self.baseline = candidate; self.candidate = baseline; comparison = reversed
        } catch { errorMessage = error.localizedDescription }
    }
    private func importPacket(_ selection: Result<[URL], Error>) {
        switch selection {
        case .failure(let error):
            if (error as NSError).code != NSUserCancelledError { errorMessage = error.localizedDescription }
        case .success(let urls):
            guard let url = urls.first, !isLoading else { return }
            let selectedSlot = slot
            isLoading = true
            importTask = Task { @MainActor in
                defer { isLoading = false; verificationTask = nil; importTask = nil }
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                do {
                    let task = Task.detached(priority: .userInitiated) {
                        try Task.checkCancellation()
                        let result = try TraceVerifiedPacket.load(url: url)
                        try Task.checkCancellation()
                        return result
                    }
                    verificationTask = task
                    let loaded = try await task.value
                    try Task.checkCancellation()
                    // Validate the proposed pair before publishing either slot; a
                    // wrong-case or failed file never replaces a working selection.
                    let proposedBaseline = selectedSlot == .baseline ? loaded : baseline
                    let proposedCandidate = selectedSlot == .candidate ? loaded : candidate
                    let result: TracePacketComparison?
                    if let proposedBaseline, let proposedCandidate {
                        result = try TracePacketComparison.compare(baseline: proposedBaseline, candidate: proposedCandidate)
                    } else { result = nil }
                    if selectedSlot == .baseline { baseline = loaded } else { candidate = loaded }
                    comparison = result
                } catch is CancellationError {
                    // Navigation/lock cancellation retains the previous selection.
                } catch { errorMessage = error.localizedDescription }
            }
        }
    }
}
