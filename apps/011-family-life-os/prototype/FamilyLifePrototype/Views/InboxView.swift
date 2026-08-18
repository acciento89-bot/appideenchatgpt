import SwiftUI

struct InboxView: View {
    @Bindable var store: DemoStore
    @State private var filter: InboxFilter = .open

    enum InboxFilter: String, CaseIterable, Identifiable {
        case open = "Offen"
        case processed = "Verarbeitet"
        case all = "Alle"

        var id: Self { self }
    }

    private var visibleItems: [InboxSource] {
        let sorted = store.inboxItems.sorted { $0.createdAt > $1.createdAt }
        switch filter {
        case .open:
            return sorted.filter { [.queued, .uploading, .processing, .review, .partial, .failed].contains($0.status) }
        case .processed:
            return sorted.filter { $0.status == .done }
        case .all:
            return sorted
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(InboxFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .accessibilityIdentifier("inbox-filter")
            }

            if visibleItems.isEmpty {
                ContentUnavailableView {
                    Label("Nichts offen", systemImage: "tray")
                } description: {
                    Text("Neue Fotos, PDFs, Texte oder Spracheingaben erscheinen hier.")
                } actions: {
                    Button("Etwas hinzufügen") {
                        store.openSignatureReview()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(visibleItems) { source in
                        if source.status == .review || source.status == .partial {
                            Button {
                                store.openReview(sourceID: source.id)
                            } label: {
                                InboxRow(source: source, isActionable: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Öffnet die erkannten Vorschläge zur Prüfung")
                        } else {
                            InboxRow(source: source, isActionable: false)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Inbox")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Foto aufnehmen", systemImage: "camera") {
                        store.openSignatureReview()
                    }
                    Button("Foto/Screenshot wählen", systemImage: "photo.on.rectangle") {
                        store.openSignatureReview()
                    }
                    Button("Dokument/PDF importieren", systemImage: "doc") {
                        store.openSignatureReview()
                    }
                    Button("Text einfügen", systemImage: "text.alignleft") {
                        store.openSignatureReview()
                    }
                    Button("Sprechen", systemImage: "waveform") {
                        store.openSignatureReview()
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Zur Inbox hinzufügen")
                .accessibilityIdentifier("inbox-add")
            }
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
                    .fixedSize(horizontal: false, vertical: true)

                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 6) {
                        StatusPill(status: source.status)
                        proposalText
                    }
                } else {
                    HStack(spacing: 8) {
                        StatusPill(status: source.status)
                        proposalText
                    }
                }

                if let message = source.errorMessage {
                    Label(
                        message,
                        systemImage: source.status == .failed ? "exclamationmark.triangle.fill" : "wifi.slash"
                    )
                    .font(.caption)
                    .foregroundStyle(source.status == .failed ? Color.red : Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            if isActionable {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            } else if source.status == .processing || source.status == .uploading {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(source.status.displayName)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("inbox-source-\(source.id.uuidString)")
    }

    @ViewBuilder
    private var proposalText: some View {
        if source.proposalCount > 0 {
            Text("\(source.proposalCount) Vorschläge")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Inbox – Mixed") {
    NavigationStack {
        InboxView(store: DemoStore())
    }
}

#Preview("Inbox – Dark") {
    NavigationStack {
        InboxView(store: DemoStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("Inbox – Accessibility") {
    NavigationStack {
        InboxView(store: DemoStore())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
