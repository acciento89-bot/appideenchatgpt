import PhotosUI
import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { CreateRapportView() }
                .tabItem { Label("Erstellen", systemImage: "waveform.and.mic") }
            NavigationStack { HistoryView() }
                .tabItem { Label("Rapporte", systemImage: "doc.text") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Mehr", systemImage: "gearshape") }
        }
        .tint(CraftTheme.orange)
    }
}

struct CreateRapportView: View {
    @EnvironmentObject private var store: RapportStore
    @EnvironmentObject private var usage: UsageMeter
    @EnvironmentObject private var entitlements: EntitlementStore
    @EnvironmentObject private var profileStore: CompanyProfileStore
    @StateObject private var speech = SpeechTranscriber()
    @State private var draft = RapportDraft()
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var shareItem: ShareItem?
    @State private var showPaywall = false
    private let service = HybridRapportService()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                hero
                contextCard
                inputCard
                if !draft.reportText.isEmpty { resultCard }
            }
            .padding(16)
            .padding(.bottom, 112)
        }
        .background(CraftTheme.background.ignoresSafeArea())
        .navigationTitle("Neuer Rapport")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: speech.transcript) { _, newValue in draft.rawText = newValue }
        .alert("Hinweis", isPresented: Binding(get: { errorMessage != nil || speech.errorMessage != nil }, set: { if !$0 { errorMessage = nil; speech.errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil; speech.errorMessage = nil }
        } message: { Text(errorMessage ?? speech.errorMessage ?? "") }
        .sheet(item: $shareItem) { ShareSheet(url: $0.url) }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var hero: some View {
        CraftCard {
            HStack(spacing: 14) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(CraftTheme.orange)
                    .frame(width: 54, height: 54)
                    .background(CraftTheme.background, in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text("HANDWERK → RAPPORT").font(.caption.bold()).foregroundStyle(CraftTheme.cyan)
                    Text("Sprich frei. Wir machen es professionell.").font(.title3.bold())
                    Text(entitlements.isPro ? "PRO · Unbegrenzte KI-Rapporte" : "Noch \(usage.remaining) kostenlose KI-Rapporte diesen Monat")
                        .font(.caption).foregroundStyle(CraftTheme.textMuted)
                    if !entitlements.isPro {
                        Button("Pro freischalten") { showPaywall = true }
                            .font(.caption.bold()).foregroundStyle(CraftTheme.orange)
                    }
                }
            }
        }
    }

    private var contextCard: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Einsatz", systemImage: "mappin.and.ellipse").font(.headline)
                Picker("Gewerk", selection: $draft.trade) {
                    ForEach(TradeCategory.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                TextField("Kunde / Auftraggeber", text: $draft.customer).textFieldStyle(CraftTextFieldStyle())
                TextField("Einsatzort", text: $draft.location).textFieldStyle(CraftTextFieldStyle())
                TextField("Objekt / Anlage / Bauteil", text: $draft.system).textFieldStyle(CraftTextFieldStyle())
                Picker("Stil", selection: $draft.tone) {
                    ForEach(RapportTone.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var inputCard: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Was wurde gemacht?", systemImage: "quote.bubble").font(.headline)
                    Spacer()
                    if speech.isRecording { Text("AUFNAHME").font(.caption.bold()).foregroundStyle(.red) }
                }
                TextEditor(text: $draft.rawText)
                    .frame(minHeight: 170)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(CraftTheme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(alignment: .topLeading) {
                        if draft.rawText.isEmpty {
                            Text("Beispiel: Beim Kunden angekommen, Wasser unter der Dusche festgestellt …")
                                .foregroundStyle(CraftTheme.textMuted)
                                .padding(.horizontal, 15).padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                Button {
                    Task {
                        if !speech.isRecording { speech.transcript = draft.rawText }
                        await speech.toggle()
                    }
                } label: {
                    Label(speech.isRecording ? "Aufnahme beenden" : "Rapport einsprechen", systemImage: speech.isRecording ? "stop.fill" : "mic.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(CraftTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14))
                }
                .foregroundStyle(.white)

                Button(action: generate) {
                    if isGenerating { ProgressView().tint(.white) } else { Label("Professionellen Rapport erstellen", systemImage: "sparkles") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isGenerating || draft.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!usage.mayGenerate && !entitlements.isPro))
            }
        }
    }

    private var resultCard: some View {
        CraftCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Fertiger Rapport", systemImage: "checkmark.seal.fill").font(.headline).foregroundStyle(CraftTheme.cyan)
                    Spacer()
                    Text("BEARBEITBAR").font(.caption2.bold()).foregroundStyle(CraftTheme.orange)
                }
                TextEditor(text: $draft.reportText)
                    .frame(minHeight: 250)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .background(CraftTheme.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 14))
                Text("Bitte Inhalt, Messwerte und ausgeführte Arbeiten vor Verwendung prüfen.")
                    .font(.caption).foregroundStyle(CraftTheme.textMuted)
                HStack {
                    Button("Speichern", systemImage: "square.and.arrow.down") { store.save(draft) }
                    Spacer()
                    Button("PDF teilen", systemImage: "square.and.arrow.up") {
                        store.save(draft)
                        do { shareItem = ShareItem(url: try PDFExporter.makePDF(for: draft, profile: profileStore.profile)) } catch { errorMessage = error.localizedDescription }
                    }
                }
                .buttonStyle(.bordered)
                .tint(CraftTheme.cyan)
            }
        }
    }

    private func generate() {
        guard usage.mayGenerate || entitlements.isPro else { showPaywall = true; return }
        isGenerating = true
        Task {
            do {
                draft.reportText = try await service.generate(from: draft)
                if !entitlements.isPro { usage.recordGeneration() }
            } catch { errorMessage = error.localizedDescription }
            isGenerating = false
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: RapportStore

    var body: some View {
        Group {
            if store.reports.isEmpty {
                ContentUnavailableView("Noch keine Rapporte", systemImage: "doc.text.magnifyingglass", description: Text("Gespeicherte Arbeitsrapporte erscheinen hier."))
            } else {
                List {
                    ForEach(store.reports) { report in NavigationLink(value: report) { ReportRow(report: report) } }
                        .onDelete(perform: store.delete)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(CraftTheme.background.ignoresSafeArea())
        .navigationTitle("Rapporte")
        .navigationDestination(for: RapportDraft.self) { report in
            ReportDetailView(report: report)
        }
    }
}

struct ReportRow: View {
    let report: RapportDraft
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(report.displayTitle).font(.headline)
            Text([report.trade.title, report.location, report.system].filter { !$0.isEmpty }.joined(separator: " · ")).font(.subheadline).foregroundStyle(CraftTheme.textMuted)
            Text(report.updatedAt, format: .dateTime.day().month().year().hour().minute()).font(.caption).foregroundStyle(CraftTheme.orange)
        }.padding(.vertical, 6)
    }
}

struct ReportDetailView: View {
    @EnvironmentObject private var store: RapportStore
    @EnvironmentObject private var profileStore: CompanyProfileStore
    @State var report: RapportDraft
    @State private var shareItem: ShareItem?

    var body: some View {
        ScrollView {
            CraftCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(report.displayTitle).font(.title2.bold())
                    if !report.location.isEmpty { Label(report.location, systemImage: "mappin") }
                    if !report.system.isEmpty { Label(report.system, systemImage: "wrench.adjustable") }
                    Divider()
                    TextEditor(text: $report.reportText).frame(minHeight: 360).scrollContentBackground(.hidden)
                    Button("Änderungen speichern") { store.save(report) }.buttonStyle(PrimaryButtonStyle())
                    Button("PDF teilen", systemImage: "square.and.arrow.up") {
                        if let url = try? PDFExporter.makePDF(for: report, profile: profileStore.profile) { shareItem = ShareItem(url: url) }
                    }
                        .buttonStyle(.bordered).tint(CraftTheme.cyan)
                }
            }.padding(16).padding(.bottom, 112)
        }
        .background(CraftTheme.background.ignoresSafeArea())
        .sheet(item: $shareItem) { ShareSheet(url: $0.url) }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var usage: UsageMeter
    @EnvironmentObject private var profileStore: CompanyProfileStore
    @EnvironmentObject private var entitlements: EntitlementStore
    @State private var selectedLogo: PhotosPickerItem?
    @State private var showPaywall = false
    private let privacyURL = URL(string: "https://kamilunavo.com/privacy")!
    private let standardEULAURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CraftCard {
                    Text("Rapport AI").font(.title2.bold())
                    Text("Kamilunavo · Für alle Gewerke").foregroundStyle(CraftTheme.cyan)
                    Text("Deine Entwürfe und fertigen Rapporte bleiben lokal auf diesem Gerät.").foregroundStyle(CraftTheme.textMuted).padding(.top, 4)
                }
                CraftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Firmenprofil für PDF", systemImage: "building.2.fill").font(.headline)
                        TextField("Firmenname", text: $profileStore.profile.companyName).textFieldStyle(CraftTextFieldStyle())
                        TextField("Ansprechpartner", text: $profileStore.profile.ownerName).textFieldStyle(CraftTextFieldStyle())
                        TextField("Anschrift", text: $profileStore.profile.address).textFieldStyle(CraftTextFieldStyle())
                        TextField("Telefon", text: $profileStore.profile.phone).textFieldStyle(CraftTextFieldStyle()).keyboardType(.phonePad)
                        TextField("E-Mail", text: $profileStore.profile.email).textFieldStyle(CraftTextFieldStyle()).keyboardType(.emailAddress).textInputAutocapitalization(.never)
                        PhotosPicker(selection: $selectedLogo, matching: .images) {
                            Label(profileStore.profile.logoData == nil ? "Firmenlogo auswählen" : "Firmenlogo ändern", systemImage: "photo.badge.plus")
                        }
                        .onChange(of: selectedLogo) { _, item in Task { await profileStore.importLogo(from: item) } }
                        if profileStore.profile.logoData != nil {
                            Button("Logo entfernen", role: .destructive) { profileStore.removeLogo() }
                        }
                    }
                }
                CraftCard {
                    Label(entitlements.isPro ? "Rapport AI Pro" : "Kostenloser Tarif", systemImage: entitlements.isPro ? "checkmark.seal.fill" : "gauge.with.dots.needle.33percent").font(.headline)
                    if entitlements.isPro {
                        Text("Unbegrenzte KI-Rapporte sind aktiv.").foregroundStyle(CraftTheme.cyan)
                    } else {
                        ProgressView(value: Double(usage.usedThisMonth), total: Double(usage.freeLimit)).tint(CraftTheme.orange)
                        Text("\(usage.usedThisMonth) von \(usage.freeLimit) KI-Rapporten verwendet").foregroundStyle(CraftTheme.textMuted)
                        Button("Pro ansehen") { showPaywall = true }.buttonStyle(PrimaryButtonStyle())
                    }
                }
                CraftCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Datenschutz", systemImage: "lock.shield.fill").font(.headline)
                        Text("Keine Zugangsdaten und keine API-Schlüssel werden in der App gespeichert. Bei aktivierter KI-Verarbeitung wird nur der eingegebene Rapportinhalt an den geschützten Dienst übertragen.")
                            .font(.subheadline).foregroundStyle(CraftTheme.textMuted)
                        Link("Datenschutzerklärung", destination: privacyURL)
                        Link("Nutzungsbedingungen (Apple EULA)", destination: standardEULAURL)
                    }
                }
            }.padding(16).padding(.bottom, 112)
        }
        .background(CraftTheme.background.ignoresSafeArea())
        .navigationTitle("Mehr")
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: [url], applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}
