import SwiftUI

struct InboxView: View {
    @Bindable var store: DemoStore
    @State private var filter: InboxFilter = .open
    @State private var isCapturePresented = false
    @State private var selectedSource: InboxSource?

    enum InboxFilter: String, CaseIterable, Identifiable {
        case open = "Offen"
        case processed = "Verarbeitet"
        case all = "Alle"
        var id: Self { self }
    }

    private var visibleItems: [InboxSource] {
        let sorted = store.inboxItems.filter { !$0.isArchived }.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .open: return sorted.filter { [.queued, .uploading, .processing, .review, .partial, .failed].contains($0.status) }
        case .processed: return sorted.filter { $0.status == .done }
        case .all: return sorted
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(InboxFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if visibleItems.isEmpty {
                ContentUnavailableView {
                    Label("Nichts offen", systemImage: "tray")
                } description: {
                    Text("Fotos, PDFs, Texte, Screenshots oder Spracheingaben erscheinen hier.")
                } actions: {
                    Button("Etwas hinzufügen") { isCapturePresented = true }
                        .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(visibleItems) { source in
                        Button {
                            if source.status == .review || source.status == .partial {
                                store.openReviewV1(sourceID: source.id)
                            } else {
                                selectedSource = source
                            }
                        } label: {
                            InboxRow(source: source, isActionable: true)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if source.isLocalOnly {
                                Button {
                                    store.retryQueuedSourceV1(source.id)
                                } label: {
                                    Label("Senden", systemImage: "arrow.up.circle")
                                }
                                .tint(.indigo)

                                Button(role: .destructive) {
                                    store.discardQueuedSourceV1(source.id)
                                } label: {
                                    Label("Verwerfen", systemImage: "trash")
                                }
                            } else {
                                Button {
                                    store.archiveSourceV1(source.id, archived: true)
                                } label: {
                                    Label("Archiv", systemImage: "archivebox")
                                }
                                .tint(.indigo)

                                if source.status == .failed {
                                    Button {
                                        store.retrySourceV1(source.id, extractedText: source.sourceText)
                                    } label: {
                                        Label("Erneut", systemImage: "arrow.clockwise")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                        .contextMenu {
                            Button("Quelle ansehen", systemImage: "doc.viewfinder") { selectedSource = source }
                            if source.isLocalOnly {
                                Button("Jetzt senden", systemImage: "arrow.up.circle") {
                                    store.retryQueuedSourceV1(source.id)
                                }
                                Button("Lokale Quelle verwerfen", systemImage: "trash", role: .destructive) {
                                    store.discardQueuedSourceV1(source.id)
                                }
                            } else {
                                if source.status == .failed {
                                    Button("Analyse erneut versuchen", systemImage: "arrow.clockwise") {
                                        store.retrySourceV1(source.id, extractedText: source.sourceText)
                                    }
                                }
                                Button("Archivieren", systemImage: "archivebox") {
                                    store.archiveSourceV1(source.id, archived: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Inbox")
        .refreshable {
            await store.refreshHosted()
            await store.overlayOfflineSourcesV1()
            await store.syncOfflineSourcesV1()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { isCapturePresented = true } label: {
                    if store.isRepositoryBusy { ProgressView() } else { Image(systemName: "plus") }
                }
                .disabled(store.isRepositoryBusy)
                .accessibilityLabel("Zur Inbox hinzufügen")
            }
        }
        .sheet(isPresented: $isCapturePresented) {
            CaptureView(store: store)
        }
        .sheet(item: $selectedSource) { source in
            NavigationStack { SourceDetailView(store: store, source: source) }
        }
    }
}

private struct InboxRow: View {
    let source: InboxSource
    let isActionable: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: source.kind.systemImage)
                .font(.title3)
                .foregroundStyle(source.status.tint)
                .frame(width: 42, height: 42)
                .background(source.status.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(source.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(source.kind.displayName) · \(source.createdAt.formatted(.dateTime.day().month().hour().minute()))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 6) { statusContent }
                    } else {
                        HStack(spacing: 8) { statusContent }
                    }
                }

                if let message = source.errorMessage {
                    Label(message, systemImage: source.isLocalOnly ? "externaldrive.badge.wifi" : (source.status == .failed ? "exclamationmark.triangle.fill" : "wifi.slash"))
                        .font(.caption)
                        .foregroundStyle(source.status == .failed && !source.isLocalOnly ? Color.red : Color.secondary)
                }
            }

            Spacer(minLength: 8)
            if source.status == .processing || source.status == .uploading {
                ProgressView().controlSize(.small)
            } else if isActionable {
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var statusContent: some View {
        StatusPill(status: source.status)
        if source.isLocalOnly {
            Text("lokal gesichert").font(.caption).foregroundStyle(.secondary)
        } else if source.proposalCount > 0 {
            Text("\(source.proposalCount) Vorschläge").font(.caption).foregroundStyle(.secondary)
        }
    }
}

#Preview { NavigationStack { InboxView(store: DemoStore()) } }
