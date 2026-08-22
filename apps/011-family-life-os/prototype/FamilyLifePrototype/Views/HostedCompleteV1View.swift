import Supabase
import SwiftUI

struct HostedCompleteV1View: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isAuthenticated = false
    @State private var hasInitialAuthState = false
    @State private var authError: String?
    @State private var pendingInviteToken: String?
    @State private var appLock = FamilyAppLock()
    @State private var loaderGeneration = UUID()

    var body: some View {
        ZStack {
            Group {
                if !hasInitialAuthState {
                    ProgressView("Session wird geprüft …")
                } else if !isAuthenticated {
                    CompleteAuthView(errorMessage: $authError)
                } else if let pendingInviteToken {
                    CompleteInviteAcceptanceView(token: pendingInviteToken) {
                        self.pendingInviteToken = nil
                        UserDefaults.standard.removeObject(forKey: "family.pendingInvite")
                        loaderGeneration = UUID()
                    }
                } else {
                    CompleteFamilyLoaderView(generation: loaderGeneration)
                }
            }

            if appLock.isEnabled && !appLock.isUnlocked && isAuthenticated {
                Rectangle().fill(.regularMaterial).ignoresSafeArea()
                VStack(spacing: 18) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 52)).foregroundStyle(.indigo)
                    Text("Familie gesperrt").font(.title2.bold())
                    Button("Entsperren") { Task { await appLock.unlock() } }
                        .buttonStyle(.borderedProminent)
                    if let error = appLock.errorMessage {
                        Text(error).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
                .padding(28)
            }
        }
        .task {
            if let token = UserDefaults.standard.string(forKey: "family.pendingInvite") {
                pendingInviteToken = token
            }
            for await state in SupabaseEnvironment.client.auth.authStateChanges {
                switch state.event {
                case .initialSession, .signedIn, .signedOut:
                    isAuthenticated = state.session != nil
                    hasInitialAuthState = true
                    if state.session != nil { authError = nil }
                    if state.session == nil { appLock.isUnlocked = true }
                default: break
                }
            }
        }
        .onOpenURL { url in
            handle(url)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { appLock.lock() }
            else if appLock.isEnabled && !appLock.isUnlocked { Task { await appLock.unlock() } }
        }
    }

    private func handle(_ url: URL) {
        if SupabaseEnvironment.isExpectedAuthRedirect(url) {
            Task {
                do {
                    _ = try await SupabaseEnvironment.client.auth.session(from: url)
                    isAuthenticated = true
                    hasInitialAuthState = true
                    authError = nil
                } catch {
                    authError = error.localizedDescription
                    hasInitialAuthState = true
                }
            }
            return
        }

        guard url.scheme?.caseInsensitiveCompare("de.kamilunavo.familyprototype") == .orderedSame,
              url.host?.caseInsensitiveCompare("invite") == .orderedSame,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
              !token.isEmpty else { return }

        pendingInviteToken = token
        UserDefaults.standard.set(token, forKey: "family.pendingInvite")
    }
}

private struct CompleteAuthView: View {
    @Binding var errorMessage: String?
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var isSendingLink = false
    @State private var didSendLink = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 44)).foregroundStyle(.indigo).accessibilityHidden(true)
                        Text("Familienalltag rein. Klarer Plan raus.").font(.title2.bold())
                        Text("Melde dich an, damit euer gemeinsamer Plan, eure Inbox und privaten Quellen sicher synchronisiert werden.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Mit E-Mail und Passwort") {
                    TextField("name@beispiel.de", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                    SecureField("Passwort", text: $password)
                        .textContentType(.password)
                    Button {
                        signInWithPassword()
                    } label: {
                        HStack {
                            if isSigningIn { ProgressView() }
                            Text(isSigningIn ? "Anmeldung läuft …" : "Anmelden")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!validCredentials || isSigningIn || isSendingLink)
                }

                Section {
                    Button {
                        sendMagicLink()
                    } label: {
                        HStack {
                            if isSendingLink { ProgressView() }
                            Text(isSendingLink ? "Wird gesendet …" : "Stattdessen Anmeldelink senden")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!validEmail || isSendingLink || isSigningIn)
                } header: {
                    Text("Anmeldung ohne Passwort")
                } footer: {
                    Text("Der Anmeldelink öffnet diese App wieder und erstellt eine sichere Supabase-Session.")
                }

                if didSendLink {
                    Section {
                        Label("Link gesendet. Bitte Postfach prüfen.", systemImage: "envelope.badge.fill")
                            .foregroundStyle(.green)
                    }
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Anmelden")
        }
    }

    private var cleanEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var validEmail: Bool {
        cleanEmail.contains("@") && cleanEmail.contains(".")
    }

    private var validCredentials: Bool {
        validEmail && !password.isEmpty
    }

    private func signInWithPassword() {
        guard validCredentials else { return }
        isSigningIn = true
        didSendLink = false
        errorMessage = nil
        Task {
            defer { isSigningIn = false }
            do {
                try await SupabaseEnvironment.client.auth.signIn(
                    email: cleanEmail,
                    password: password
                )
            } catch {
                errorMessage = "Anmeldung fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func sendMagicLink() {
        guard validEmail else { return }
        isSendingLink = true
        didSendLink = false
        errorMessage = nil
        Task {
            defer { isSendingLink = false }
            do {
                try await SupabaseEnvironment.client.auth.signInWithOTP(
                    email: cleanEmail,
                    redirectTo: SupabaseEnvironment.authRedirectURL
                )
                didSendLink = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct CompleteInviteAcceptanceView: View {
    let token: String
    let completed: () -> Void
    @State private var displayName = ""
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Du wurdest zu einer Familie eingeladen.", systemImage: "person.3.fill")
                        .font(.headline)
                    TextField("Dein Name", text: $displayName).textContentType(.name)
                }
                Section {
                    Button("Einladung annehmen") {
                        accept()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isBusy)
                }
                if let errorMessage {
                    Section { Label(errorMessage, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                }
            }
            .navigationTitle("Familie beitreten")
        }
    }

    private func accept() {
        isBusy = true
        Task {
            defer { isBusy = false }
            do {
                _ = try await SupabaseFamilyRepository().acceptInvite(token: token, displayName: displayName)
                completed()
            } catch { errorMessage = error.localizedDescription }
        }
    }
}

private struct CompleteFamilyLoaderView: View {
    let generation: UUID
    @State private var store: DemoStore?
    @State private var loadError: String?
    @State private var isShowingDiagnostics = false
    @State private var isRunningSmokeTest = false
    @State private var smokeReport: HostedSmokeTestReport?

    private let repository = SupabaseFamilyRepository()
    private let cache = FamilySnapshotCache()
    private let realtime = FamilyRealtimeSyncService()

    var body: some View {
        Group {
            if let store {
                RootView(store: store)
                    .task { await runRealtime(store: store) }
            } else if let loadError {
                ContentUnavailableView {
                    Label("Familie konnte nicht geladen werden", systemImage: "icloud.slash")
                } description: { Text(loadError) }
                actions: {
                    Button("Erneut versuchen") { self.loadError = nil; Task { await load() } }.buttonStyle(.borderedProminent)
                    Button("Abmelden", role: .destructive) { Task { try? await SupabaseEnvironment.client.auth.signOut() } }
                }
            } else {
                ProgressView("Familie wird geladen …")
            }
        }
        .task(id: generation) { await load() }
        .overlay(alignment: .bottomTrailing) {
            if store != nil {
                Button { isShowingDiagnostics = true } label: {
                    Image(systemName: "stethoscope").frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent).clipShape(Circle()).padding(18)
                .accessibilityLabel("Hosted Backend testen")
            }
        }
        .sheet(isPresented: $isShowingDiagnostics) {
            CompleteDiagnosticsView(isRunning: isRunningSmokeTest, report: smokeReport, run: runSmokeTest)
        }
    }

    private func load() async {
        if store == nil, let cached = await cache.load() {
            store = DemoStore(repository: repository, snapshot: cached)
        }
        do {
            let snapshot = try await repository.completeSnapshot()
            await cache.save(snapshot)
            if let store { store.applySnapshot(snapshot) }
            else { store = DemoStore(repository: repository, snapshot: snapshot) }
            await FamilyNotificationService.shared.reschedule(snapshot: snapshot, preferences: snapshot.notificationPreferences)
            loadError = nil
        } catch {
            if store == nil { loadError = error.localizedDescription }
        }
    }

    private func runRealtime(store: DemoStore) async {
        for await _ in await realtime.changes() {
            guard !Task.isCancelled else { return }
            do {
                let snapshot = try await repository.completeSnapshot()
                await cache.save(snapshot)
                store.applySnapshot(snapshot)
                await FamilyNotificationService.shared.reschedule(snapshot: snapshot, preferences: snapshot.notificationPreferences)
            } catch {
                store.repositoryErrorMessage = "Live-Sync konnte nicht aktualisiert werden: \(error.localizedDescription)"
            }
        }
    }

    private func runSmokeTest() {
        guard !isRunningSmokeTest else { return }
        isRunningSmokeTest = true; smokeReport = nil
        Task {
            smokeReport = await HostedSmokeTestService(repository: repository).run()
            isRunningSmokeTest = false
        }
    }
}

private struct CompleteDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss
    let isRunning: Bool
    let report: HostedSmokeTestReport?
    let run: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Hosted-Konfiguration") {
                    Label("Frankfurt / EU", systemImage: "server.rack")
                    Label("RLS + private Storage + Realtime", systemImage: "lock.shield")
                    Text(SupabaseEnvironment.authRedirectURL.absoluteString).font(.footnote.monospaced()).textSelection(.enabled)
                }
                Section {
                    Button(action: run) {
                        HStack {
                            if isRunning { ProgressView() } else { Image(systemName: "play.fill") }
                            Text(isRunning ? "Hosted E2E läuft …" : "Hosted E2E jetzt prüfen").frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent).disabled(isRunning)
                }
                if let report {
                    Section {
                        Label(report.passed ? "Hosted E2E bestanden" : "Hosted E2E fehlgeschlagen", systemImage: report.passed ? "checkmark.seal.fill" : "xmark.octagon.fill")
                            .foregroundStyle(report.passed ? .green : .red)
                    }
                    Section("Prüfschritte") {
                        ForEach(report.steps) { step in
                            Label {
                                VStack(alignment: .leading) {
                                    Text(step.title).fontWeight(.semibold)
                                    Text(step.detail).font(.caption).foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: step.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(step.passed ? .green : .red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Backend-Diagnose")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}
