import StoreKit
import Supabase
import SwiftUI

struct FamilySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    @Bindable var appLock: FamilyAppLock
    @State private var proStore = FamilyProStore()
    @State private var preferences = NotificationPreferences()
    @State private var notificationsGranted = false
    @State private var isLoading = true
    @State private var showDeleteConfirmation = false
    @State private var statusMessage: String?

    private let familyPrivacyURL = URL(string: "https://www.kamilunavo.com/family/privacy")!
    private let familyTermsURL = URL(string: "https://www.kamilunavo.com/family/terms")!

    var body: some View {
        NavigationStack {
            Form {
                Section("Family Pro") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(proStore.isPro ? "Family Pro aktiv" : "Kostenlos")
                                .font(.headline)
                            Text(proStore.isPro ? "Alle Pro-Funktionen auf diesem Apple-Account freigeschaltet." : "Mehr AI-Importe, Speicher und erweiterte Familienfunktionen.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: proStore.isPro ? "checkmark.seal.fill" : "sparkles")
                            .foregroundStyle(proStore.isPro ? .green : .indigo)
                    }

                    if !proStore.isPro {
                        if isLoading && proStore.products.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Family Pro wird geladen …")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        ForEach(proStore.products, id: \.id) { product in
                            Button {
                                Task { await proStore.purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.displayName)
                                        Text(product.id == FamilyProPolicy.annualID ? "Jährliche Abrechnung" : "Monatliche Abrechnung")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(product.displayPrice).fontWeight(.semibold)
                                }
                            }
                            .disabled(proStore.isBusy)
                        }

                        if proStore.products.isEmpty && !isLoading && !proStore.isBusy {
                            Text("Family-Pro-Produkte konnten noch nicht aus App Store Connect geladen werden. Die übrige App bleibt testbar.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Käufe wiederherstellen") {
                        Task { await proStore.restore() }
                    }
                    .disabled(proStore.isBusy)

                    if proStore.isBusy {
                        ProgressView()
                    }

                    if let proStatus = proStore.statusMessage {
                        Label(proStatus, systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let proError = proStore.errorMessage {
                        Label(proError, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Family Pro ist ein automatisch verlängerndes Abonnement. Die Abrechnung erfolgt über Apple. Das Abo verlängert sich, sofern es nicht mindestens 24 Stunden vor Ablauf in den Apple-ID-Abonnementeinstellungen gekündigt wird.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            Link("Datenschutz", destination: familyPrivacyURL)
                            Link("Nutzungsbedingungen", destination: familyTermsURL)
                        }
                        .font(.caption)
                    }
                }

                Section("Benachrichtigungen") {
                    Toggle("Terminerinnerungen", isOn: $preferences.eventReminders)
                    Toggle("Aufgaben & Fristen", isOn: $preferences.taskReminders)
                    Toggle("Vorbereitungen", isOn: $preferences.preparationReminders)
                    Toggle("Neue Zuweisungen", isOn: $preferences.assignmentUpdates)
                    Toggle("Inbox wartet auf Prüfung", isOn: $preferences.inboxReview)
                    Toggle("Tagesübersicht", isOn: $preferences.dailyDigest)

                    Button(notificationsGranted ? "Benachrichtigungen aktualisieren" : "Benachrichtigungen erlauben") {
                        Task {
                            do {
                                notificationsGranted = try await FamilyNotificationService.shared.requestAuthorization()
                                try await SupabaseFamilyRepository().saveNotificationPreferences(preferences)
                                await FamilyNotificationService.shared.reschedule(snapshot: currentSnapshot, preferences: preferences)
                                statusMessage = "Benachrichtigungen gespeichert."
                            } catch { statusMessage = error.localizedDescription }
                        }
                    }
                }

                Section("Datenschutz & Sicherheit") {
                    Toggle("Mit Face ID / Touch ID sperren", isOn: $appLock.isEnabled)
                    Label("Private Dokumente liegen nicht öffentlich im Storage.", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("AI-Verarbeitung läuft ausschließlich serverseitig.", systemImage: "server.rack")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("Datenschutzhinweise für die Familien-App", destination: familyPrivacyURL)
                        .font(.caption)
                }

                if !store.activity.isEmpty {
                    Section("Letzte Änderungen") {
                        ForEach(store.activity.prefix(12)) { entry in
                            HStack(alignment: .top) {
                                Image(systemName: icon(for: entry))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.displayText)
                                    Text(entry.createdAt, format: .dateTime.day().month().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button("Daten neu laden") {
                        Task { await store.refreshHosted() }
                    }
                    Button("Abmelden") {
                        Task { try? await SupabaseEnvironment.client.auth.signOut() }
                    }
                    Button("Haushalt löschen", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Beim Löschen des Haushalts werden Plan, Inbox-Quellen, private Dateien und Familienzuordnungen entfernt. Diese Aktion kann nicht rückgängig gemacht werden.")
                }

                if let statusMessage {
                    Section { Text(statusMessage).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        Task { try? await SupabaseFamilyRepository().saveNotificationPreferences(preferences) }
                        dismiss()
                    }
                }
            }
            .task {
                async let products: Void = proStore.refresh()
                do { preferences = try await SupabaseFamilyRepository().loadNotificationPreferences() }
                catch { statusMessage = error.localizedDescription }
                _ = await products
                isLoading = false
            }
            .confirmationDialog("Haushalt endgültig löschen?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Haushalt löschen", role: .destructive) {
                    Task {
                        do {
                            try await SupabaseFamilyRepository().deleteHousehold()
                            try? await SupabaseEnvironment.client.auth.signOut()
                        } catch { statusMessage = error.localizedDescription }
                    }
                }
            }
        }
    }

    private var currentSnapshot: FamilySnapshot {
        FamilySnapshot(
            household: store.household,
            members: store.members,
            planItems: store.planItems,
            inboxItems: store.inboxItems,
            proposals: store.proposals,
            reminders: store.reminders,
            activity: store.activity,
            entitlement: store.entitlement,
            notificationPreferences: preferences
        )
    }

    private func icon(for entry: ActivityEntry) -> String {
        switch entry.entityType {
        case "plan_item": "calendar"
        case "source_item": "tray"
        case "member": "person"
        case "invite": "person.badge.plus"
        default: "clock.arrow.circlepath"
        }
    }
}
