import SwiftUI

struct RootView: View {
    @ObservedObject var store: EvidenceStore
    @State private var showsNewCase = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    stats

                    HStack {
                        Text("Cases")
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            showsNewCase = true
                        } label: {
                            Label("New Case", systemImage: "plus")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if store.cases.isEmpty {
                        ContentUnavailableView(
                            "No evidence cases yet",
                            systemImage: "checkmark.shield",
                            description: Text("Create a case before the details get fuzzy.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(store.cases.sorted(by: { $0.lastActivity > $1.lastActivity })) { evidenceCase in
                                NavigationLink {
                                    CaseDetailView(store: store, caseID: evidenceCase.id)
                                } label: {
                                    CaseCard(evidenceCase: evidenceCase)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Evidaro")
            .toolbarTitleDisplayMode(.inline)
            .sheet(isPresented: $showsNewCase) {
                NewCaseView(store: store)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 28, weight: .bold))
                    .frame(width: 52, height: 52)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Capture facts. Seal the record.")
                        .font(.title3.bold())
                    Text("Build a clean evidence timeline while the details are still fresh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Hashes help detect later changes. They are an integrity aid, not legal certification.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(store.cases.count)", label: "Cases", symbol: "folder")
            StatCard(value: "\(store.totalEvidenceCount)", label: "Evidence", symbol: "list.bullet.rectangle")
            StatCard(value: "\(store.totalSealCount)", label: "Seals", symbol: "checkmark.seal")
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CaseCard: View {
    let evidenceCase: EvidenceCase

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: evidenceCase.kind.symbol)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(evidenceCase.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(evidenceCase.kind.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Label("\(evidenceCase.evidence.count)", systemImage: "paperclip")
                    Label("\(evidenceCase.seals.count)", systemImage: "checkmark.seal")
                    Text(evidenceCase.lastActivity, style: .relative)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct NewCaseView: View {
    @ObservedObject var store: EvidenceStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var kind: EvidenceCaseKind = .property

    var body: some View {
        NavigationStack {
            Form {
                Section("Case") {
                    TextField("Short factual title", text: $title)
                    Picker("Type", selection: $kind) {
                        ForEach(EvidenceCaseKind.allCases) { option in
                            Label(option.rawValue, systemImage: option.symbol)
                                .tag(option)
                        }
                    }
                }

                Section {
                    Text("Use one case for one real-world situation. You can add notes, photos and documents to its timeline as the record grows.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Case")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        store.createCase(title: title, kind: kind)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
