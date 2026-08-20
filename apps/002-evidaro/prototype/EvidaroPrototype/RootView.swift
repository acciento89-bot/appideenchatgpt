import SwiftUI

struct RootView: View {
    @ObservedObject var store: EvidenceStore
    @ObservedObject var appLock: AppLockController
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsNewCase = false
    @State private var showsSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    stats

                    HStack {
                        Text("home.cases")
                            .font(.title2.bold())
                            .accessibilityHeading(.h2)
                        Spacer()
                        Button {
                            showsNewCase = true
                        } label: {
                            Label("home.new_case", systemImage: "plus")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if store.cases.isEmpty {
                        ContentUnavailableView(
                            "home.empty.title",
                            systemImage: "checkmark.shield",
                            description: Text("home.empty.description")
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("common.settings"))
                }
            }
            .sheet(isPresented: $showsNewCase) {
                NewCaseView(store: store)
            }
            .sheet(isPresented: $showsSettings) {
                PrivacySettingsView(appLock: appLock)
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    heroIcon
                    heroCopy
                }

                VStack(alignment: .leading, spacing: 12) {
                    heroIcon
                    heroCopy
                }
            }

            Text("home.hero.integrity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var heroIcon: some View {
        Image(systemName: "checkmark.shield.fill")
            .font(.system(size: 28, weight: .bold))
            .frame(width: 52, height: 52)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityHidden(true)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("home.hero.title")
                .font(.title3.bold())
                .accessibilityHeading(.h2)
            Text("home.hero.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var stats: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                statCards
            }
        } else {
            HStack(spacing: 10) {
                statCards
            }
        }
    }

    @ViewBuilder
    private var statCards: some View {
        StatCard(value: "\(store.cases.count)", label: L10n.string("stats.cases"), symbol: "folder")
        StatCard(value: "\(store.totalEvidenceCount)", label: L10n.string("stats.evidence"), symbol: "list.bullet.rectangle")
        StatCard(value: "\(store.totalSealCount)", label: L10n.string("stats.seals"), symbol: "checkmark.seal")
    }
}

private struct PrivacySettingsView: View {
    @ObservedObject var appLock: AppLockController
    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false

    var body: some View {
        NavigationStack {
            Form {
                Section("privacy_lock.title") {
                    Toggle(
                        "privacy_lock.require_auth",
                        isOn: Binding(
                            get: { appLock.isEnabled },
                            set: { newValue in
                                Task { await updateLock(newValue) }
                            }
                        )
                    )
                    .disabled(isUpdating || (!appLock.isAuthenticationAvailable && !appLock.isEnabled))

                    Text("privacy_lock.description")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    if !appLock.isAuthenticationAvailable && !appLock.isEnabled {
                        Label(
                            L10n.string("privacy_lock.unavailable"),
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }

                    if isUpdating || appLock.isAuthenticating {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("privacy_lock.confirming")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if let error = appLock.lastError, !error.isEmpty {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }

                Section("privacy_lock.data_boundary") {
                    Label(L10n.string("privacy_lock.local_data"), systemImage: "iphone")
                    Text("privacy_lock.integrity")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("common.settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
            .task {
                appLock.refreshAvailability()
            }
        }
    }

    @MainActor
    private func updateLock(_ newValue: Bool) async {
        guard !isUpdating else { return }
        isUpdating = true
        defer { isUpdating = false }
        _ = await appLock.setEnabled(newValue)
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
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(evidenceCase.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(evidenceCase.kind.localizedName)
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

            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(15)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format(
                "accessibility.case_card",
                evidenceCase.title,
                evidenceCase.kind.localizedName,
                evidenceCase.evidence.count,
                evidenceCase.seals.count
            )
        )
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
                Section("case.section") {
                    TextField("case.title_placeholder", text: $title)
                    Picker("case.type", selection: $kind) {
                        ForEach(EvidenceCaseKind.allCases) { option in
                            Label(option.localizedName, systemImage: option.symbol)
                                .tag(option)
                        }
                    }
                }

                Section {
                    Text("case.new.help")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("case.new.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.create") {
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
