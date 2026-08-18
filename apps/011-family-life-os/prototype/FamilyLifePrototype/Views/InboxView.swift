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
            return sorted.filter { [.uploading, .processing, .review, .partial, .failed].contains($0.status) }
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
            }

            if visibleItems.isEmpty {
                ContentUnavailableView(
                    "Nichts offen",
                    systemImage: "tray",
                    description: Text("Neue Fotos, PDFs, Texte oder Spracheingaben erscheinen hier.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(visibleItems) { source in
                        Button {
                            if source.status == .review || source.status == .partial {
                                store.openReview(sourceID: source.id)
                            }
                        } label: {
                            InboxRow(source: source)
                        }
                        .buttonStyle(.plain)
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
            }
        }
    }
}

private struct InboxRow: View {
    let source: InboxSource

    var body: some View {
        HStack(spacing: 14) {
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

                HStack(spacing: 6) {
                    Text(source.kind.displayName)
                    Text("·")
                    Text(source.createdAt, format: .dateTime.day().month().hour().minute())
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    StatusPill(status: source.status)
                    if source.proposalCount > 0 {
                        Text("\(source.proposalCount) Vorschläge")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = source.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer(minLength: 8)

            if source.status == .review || source.status == .partial {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            } else if source.status == .processing || source.status == .uploading {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
