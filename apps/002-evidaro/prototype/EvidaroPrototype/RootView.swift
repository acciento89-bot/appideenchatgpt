import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @ObservedObject var store: EvidenceStore
    @ObservedObject var appLock: AppLockController
    @ObservedObject private var entitlement = EntitlementStore.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsNewCase = false
    @State private var showsSettings = false
    @State private var showsPro = false
    @State private var showsVerificationImporter = false
    @State private var verificationResult: EvidenceBundleVerificationResult?
    @State private var verificationError: String?

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
                            if entitlement.canCreateCase(currentCount: store.cases.count) {
                                showsNewCase = true
                            } else {
                                showsPro = true
                            }
                        } label: {
                            Label("home.new_case", systemImage: "plus")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if !entitlement.isPro && store.cases.count >= EntitlementStore.freeActiveCaseLimit {
                        Button {
                            showsPro = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("pro.case_limit_title")
                                        .font(.subheadline.bold())
                                    Text("pro.case_limit_body")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .accessibilityHidden(true)
                            }
                            .padding(14)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
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
            .navigationTitle("Kamilunavo Trace")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showsVerificationImporter = true
                    } label: {
                        Image(systemName: "checkmark.shield")
                    }
                    .accessibilityLabel(L10n.string("bundle.verify_import"))
                }
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
            .sheet(isPresented: $showsPro) {
                ProUpgradeView(entitlement: entitlement)
            }
            .sheet(item: $verificationResult) { result in
                VerificationResultView(result: result)
            }
            .fileImporter(
                isPresented: $showsVerificationImporter,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false,
                onCompletion: importVerificationBundle
            )
            .alert(L10n.string("bundle.verify_failed"), isPresented: Binding(
                get: { verificationError != nil },
                set: { if !$0 { verificationError = nil } }
            )) {
                Button("common.ok", role: .cancel) { verificationError = nil }
            } message: {
                if let verificationError {
                    Text(verificationError)
                }
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
        Image(systemName: "point.3.connected.trianglepath.dotted")
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

    private func importVerificationBundle(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            verificationError = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                verificationResult = try EvidenceBundleVerifier.verify(data: data)
            } catch {
                verificationError = error.localizedDescription
            }
        }
    }
}

private struct VerificationResultView: View {
    let result: EvidenceBundleVerificationResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(
                        result.isValid ? L10n.string("bundle.result_valid") : L10n.string("bundle.result_invalid"),
                        systemImage: result.isValid ? "checkmark.shield.fill" : "xmark.shield.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(result.isValid ? Color.green : Color.red)
                    Text(result.caseTitle)
                        .font(.title3.bold())
                }

                Section(L10n.string("bundle.result_details")) {
                    LabeledContent(L10n.string("bundle.result_case_id"), value: result.caseID)
                    LabeledContent(L10n.string("bundle.result_items"), value: "\(result.itemCount)")
                    LabeledContent(
                        L10n.string("bundle.result_seals"),
                        value: "\(result.verifiedSealCount)/\(result.sealCount)"
                    )
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.string("bundle.result_manifest"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.currentManifestHash)
                            .font(.caption2.monospaced())
                            .textSelection(.enabled)
                    }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.string("bundle.result_bundle_hash"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result.bundleHash)
                            .font(.caption2.monospaced())
                            .textSelection(.enabled)
                    }
                }

                if !result.issues.isEmpty {
                    Section(L10n.string("bundle.result_issues")) {
                        ForEach(Array(result.issues.enumerated()), id: \.offset) { _, issue in
                            Label(issue, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section(L10n.string("bundle.result_boundary")) {
                    Text(L10n.string("bundle.result_boundary_text"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.string("bundle.verify_title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }
}

private struct PrivacySettingsView: View {
    @ObservedObject var appLock: AppLockController
    @ObservedObject private var entitlement = EntitlementStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    @State private var showsPro = false

    var body: some View {
        NavigationStack {
            Form {
                Section("pro.navigation") {
                    LabeledContent(
                        L10n.string("pro.status"),
                        value: entitlement.isPro ? L10n.string("pro.status_pro") : L10n.string("pro.status_free")
                    )
                    Button(entitlement.isPro ? L10n.string("pro.manage") : L10n.string("pro.upgrade")) {
                        showsPro = true
                    }
                }

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
                await entitlement.refreshEntitlements()
            }
            .sheet(isPresented: $showsPro) {
                ProUpgradeView(entitlement: entitlement)
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
