import StoreKit
import SwiftUI

struct SettingsV1View: View {
    @Environment(\.dismiss) private var dismiss
    @State private var proStore = FamilyProStore()
    @State private var appLock = FamilyAppLock()
    @State private var preferences = NotificationPreferences()
    @State private var isSavingPreferences = false
    @State private var exportDocument: FamilyExportDocument?
    @State private var showDeleteConfirmation = false
    @State private var message: String?

    let snapshot: FamilySnapshot
    let onRefresh: () async -> Void

    private let repository = SupabaseFamilyRepository()

    var body: some View {
        NavigationStack {
            List {
                Section("Family Pro") {
                    HStack {
                        Label(proStore.isPro ? "Family Pro aktiv" : "Free", systemImage: proStore.isPro ? "checkmark.seal.fill" : "person.3")
                        Spacer()
                        if proStore.isBusy { ProgressView() }
                    }

                    ForEach(proStore.products, id: \.id) { product in
                        Button {
                            Task { await proStore.purchase(product) }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(product.displayName).font(.headline)
                                    Text(product.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(product.displayPrice).font(.headline)
                            }
                        }
                    }

                    Button("Käufe wiederherstellen") { Task { await proStore.restore() } }
                } footer: {
                    Text("Family Pro erhöht später AI- und Speicherlimits. Käufe werden über StoreKit 2 geprüft.")
                }

                Section("Benachrichtigungen") {
                    Toggle("Terminerinnerungen", isOn: $preferences.eventReminders)
                    Toggle("Aufgaben & Fristen", isOn: $preferences.taskReminders)
                    Toggle("Vorbereitung", isOn: $preferences.preparationReminders)
                    Toggle("Zuweisungsänderungen", isOn: $preferences.assignmentUpdates)
                    Toggle("Inbox wartet auf Prüfung", isOn: $preferences.inboxReview)
                    Toggle("Tageszusammenfassung", isOn: $preferences.dailyDigest)

                    Button(isSavingPreferences ? "Wird gespeichert …" : "Einstellungen speichern") {
                        savePreferences()
                    }
                    .disabled(isSavingPreferences)

                    Button("Mitteilungen erlauben") {
                        Task {
                            do {
                                _ = try await FamilyNotificationService.shared.requestAuthorization()
                                await FamilyNotificationService.shared.reschedule(snapshot: snapshot, preferences: preferences)
                                message = "Benachrichtigungen wurden aktualisiert."
                            } catch { message = error.localizedDescription }
                        }
                    }
                }

                Section("Datenschutz & Sicherheit") {
                    Toggle("App mit Face ID / Touch ID sperren", isOn: $appLock.isEnabled)
                    Button("Jetzt sperren") {
                        appLock.lock()
                        Task { await appLock.unlock() }
                    }
                    .disabled(!appLock.isEnabled)

                    Button("Familien-Daten exportieren") {
                        exportDocument = FamilyExportDocument(snapshot: snapshot)
                    }
                }

                Section("Account") {
                    Button("Abmelden") {
                        Task { try? await SupabaseEnvironment.client.auth.signOut() }
                    }

                    Button("Haushalt dauerhaft löschen", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                Section("Über") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–")
                    LabeledContent("Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–")
                    Text("Interner TestFlight-Build. AI-Ergebnisse bleiben Vorschläge und werden erst nach deiner Bestätigung zu Familienplan-Daten.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message {
                    Section { Text(message).foregroundStyle(.secondary) }
                }
                if let error = proStore.errorMessage ?? appLock.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .task {
                await proStore.refresh()
                if let loaded = try? await repository.loadNotificationPreferences() {
                    preferences = loaded
                }
            }
            .alert("Haushalt wirklich löschen?", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Dauerhaft löschen", role: .destructive) {
                    Task {
                        do {
                            try await repository.deleteHousehold()
                            try? await SupabaseEnvironment.client.auth.signOut()
                        } catch { message = error.localizedDescription }
                    }
                }
            } message: {
                Text("Alle Familienmitglieder, Pläne, Inbox-Quellen und privaten Dateien dieses Haushalts werden gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .sheet(item: $exportDocument) { document in
                ShareSheet(items: [document.url])
            }
        }
    }

    private func savePreferences() {
        isSavingPreferences = true
        Task {
            defer { isSavingPreferences = false }
            do {
                try await repository.saveNotificationPreferences(preferences)
                await FamilyNotificationService.shared.reschedule(snapshot: snapshot, preferences: preferences)
                message = "Benachrichtigungseinstellungen gespeichert."
            } catch { message = error.localizedDescription }
        }
    }
}

private struct FamilyExportDocument: Identifiable {
    let id = UUID()
    let url: URL

    init?(snapshot: FamilySnapshot) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("family-life-export-\(UUID().uuidString).json")
        do { try data.write(to: url, options: .atomic); self.url = url }
        catch { return nil }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
