import Supabase
import SwiftUI

struct HostedAppView: View {
    @State private var isAuthenticated = false
    @State private var hasReceivedInitialAuthState = false
    @State private var authErrorMessage: String?
    @State private var sessionUserID: UUID?
    @State private var sessionEmail: String?
    @AppStorage("family.lastAuthCallbackUnixTime") private var lastAuthCallbackUnixTime: Double = 0
    @AppStorage("family.lastAuthCallbackUserID") private var lastAuthCallbackUserID = ""

    var body: some View {
        Group {
            if !hasReceivedInitialAuthState {
                ProgressView("Session wird geprüft …")
            } else if isAuthenticated {
                HostedFamilyLoaderView(
                    userID: sessionUserID,
                    userEmail: sessionEmail,
                    lastAuthCallbackAt: lastAuthCallbackUnixTime > 0
                        ? Date(timeIntervalSince1970: lastAuthCallbackUnixTime)
                        : nil,
                    lastAuthCallbackUserID: lastAuthCallbackUserID
                )
            } else {
                SupabaseAuthView(errorMessage: $authErrorMessage)
            }
        }
        .task {
            for await state in SupabaseEnvironment.client.auth.authStateChanges {
                switch state.event {
                case .initialSession, .signedIn, .signedOut:
                    isAuthenticated = state.session != nil
                    hasReceivedInitialAuthState = true
                    sessionUserID = state.session?.user.id
                    sessionEmail = state.session?.user.email

                    if state.session != nil {
                        authErrorMessage = nil
                    } else if state.event == .signedOut {
                        lastAuthCallbackUnixTime = 0
                        lastAuthCallbackUserID = ""
                    }
                default:
                    break
                }
            }
        }
        .onOpenURL { url in
            guard SupabaseEnvironment.isExpectedAuthRedirect(url) else {
                authErrorMessage = "Dieser Anmeldelink gehört nicht zu dieser App."
                hasReceivedInitialAuthState = true
                return
            }

            Task {
                do {
                    let session = try await SupabaseEnvironment.client.auth.session(from: url)
                    isAuthenticated = true
                    hasReceivedInitialAuthState = true
                    sessionUserID = session.user.id
                    sessionEmail = session.user.email
                    lastAuthCallbackUnixTime = Date.now.timeIntervalSince1970
                    lastAuthCallbackUserID = session.user.id.uuidString
                    authErrorMessage = nil
                } catch {
                    authErrorMessage = error.localizedDescription
                    hasReceivedInitialAuthState = true
                }
            }
        }
    }
}

private struct SupabaseAuthView: View {
    @Binding var errorMessage: String?
    @State private var email = ""
    @State private var isSending = false
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.indigo)
                            .accessibilityHidden(true)

                        Text("Familienalltag rein. Klarer Plan raus.")
                            .font(.title2.bold())
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Melde dich an, damit eure Termine, Aufgaben und importierten Informationen sicher zwischen den Familiengeräten synchronisiert werden können.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    TextField("name@beispiel.de", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("auth.email")

                    Button {
                        sendMagicLink()
                    } label: {
                        HStack {
                            if isSending {
                                ProgressView()
                            }
                            Text(isSending ? "Wird gesendet …" : "Anmeldelink senden")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidEmail || isSending)
                    .accessibilityIdentifier("auth.sendMagicLink")
                } header: {
                    Text("E-Mail")
                } footer: {
                    Text("Du erhältst einen einmal verwendbaren Link. Nach dem Öffnen kehrst du direkt in die App zurück.")
                }

                if didSend {
                    Section {
                        Label("Link gesendet. Bitte E-Mail-Postfach prüfen.", systemImage: "envelope.badge.fill")
                            .foregroundStyle(.green)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .navigationTitle("Anmelden")
        }
    }

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private func sendMagicLink() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        didSend = false
        errorMessage = nil

        Task {
            defer { isSending = false }

            do {
                try await SupabaseEnvironment.client.auth.signInWithOTP(
                    email: trimmed,
                    redirectTo: SupabaseEnvironment.authRedirectURL
                )
                didSend = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct HostedFamilyLoaderView: View {
    let userID: UUID?
    let userEmail: String?
    let lastAuthCallbackAt: Date?
    let lastAuthCallbackUserID: String

    @State private var store: DemoStore?
    @State private var errorMessage: String?
    @State private var retryToken = UUID()
    @State private var isShowingDiagnostics = false
    @State private var isRunningSmokeTest = false
    @State private var smokeReport: HostedSmokeTestReport?

    private let repository = SupabaseFamilyRepository()

    var body: some View {
        Group {
            if let store {
                RootView(store: store)
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Familie konnte nicht geladen werden", systemImage: "icloud.slash")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Erneut versuchen") {
                        self.errorMessage = nil
                        retryToken = UUID()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Abmelden", role: .destructive) {
                        signOut()
                    }
                }
            } else {
                ProgressView("Familie wird geladen …")
            }
        }
        .task(id: retryToken) {
            guard store == nil else { return }
            do {
                let snapshot = try await repository.currentSnapshot()
                store = DemoStore(repository: repository, snapshot: snapshot)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if store != nil {
                Button {
                    isShowingDiagnostics = true
                } label: {
                    Image(systemName: "stethoscope")
                        .font(.headline)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .padding(18)
                .accessibilityLabel("Hosted Backend testen")
                .accessibilityIdentifier("hosted.openDiagnostics")
            }
        }
        .sheet(isPresented: $isShowingDiagnostics) {
            HostedDiagnosticsView(
                userID: userID,
                userEmail: userEmail,
                lastAuthCallbackAt: lastAuthCallbackAt,
                lastAuthCallbackUserID: lastAuthCallbackUserID,
                isRunning: isRunningSmokeTest,
                report: smokeReport,
                run: runSmokeTest,
                signOut: signOut
            )
        }
    }

    private func runSmokeTest() {
        guard !isRunningSmokeTest else { return }
        isRunningSmokeTest = true
        smokeReport = nil

        Task {
            let service = HostedSmokeTestService(repository: repository)
            let report = await service.run()
            smokeReport = report
            isRunningSmokeTest = false
        }
    }

    private func signOut() {
        Task {
            try? await SupabaseEnvironment.client.auth.signOut()
        }
    }
}

private struct HostedDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    let userID: UUID?
    let userEmail: String?
    let lastAuthCallbackAt: Date?
    let lastAuthCallbackUserID: String
    let isRunning: Bool
    let report: HostedSmokeTestReport?
    let run: () -> Void
    let signOut: () -> Void

    private var callbackMatchesCurrentSession: Bool {
        guard let userID, !lastAuthCallbackUserID.isEmpty else { return false }
        return lastAuthCallbackUserID.caseInsensitiveCompare(userID.uuidString) == .orderedSame
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Frankfurt / EU", systemImage: "server.rack")
                    Label("Publishable Client Key", systemImage: "key.horizontal")
                    Label(
                        SupabaseEnvironment.authRedirectURL.absoluteString,
                        systemImage: "link"
                    )
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                } header: {
                    Text("Hosted-Konfiguration")
                } footer: {
                    Text("Der Test nutzt nur die angemeldete Session und die normalen RLS-geschützten Client-Rechte. Keine Service-Role-Credentials werden verwendet.")
                }

                Section {
                    Label(userEmail ?? "E-Mail nicht verfügbar", systemImage: "envelope")

                    LabeledContent("User-ID") {
                        Text(userID?.uuidString ?? "—")
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }

                    if let lastAuthCallbackAt {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Frischer Magic-Link Callback erkannt")
                                    .font(.body.weight(.semibold))
                                Text(lastAuthCallbackAt, format: .dateTime.day().month().year().hour().minute().second())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: callbackMatchesCurrentSession
                                  ? "checkmark.seal.fill"
                                  : "exclamationmark.triangle.fill")
                                .foregroundStyle(callbackMatchesCurrentSession ? .green : .orange)
                        }
                    } else {
                        Label("Noch kein frischer Magic-Link Callback in diesem Testlauf", systemImage: "link.badge.plus")
                            .foregroundStyle(.secondary)
                    }

                    if lastAuthCallbackAt != nil {
                        Label(
                            callbackMatchesCurrentSession
                                ? "Callback gehört zur aktuellen Session"
                                : "Callback und aktuelle Session stimmen nicht überein",
                            systemImage: callbackMatchesCurrentSession
                                ? "person.crop.circle.badge.checkmark"
                                : "person.crop.circle.badge.exclamationmark"
                        )
                        .foregroundStyle(callbackMatchesCurrentSession ? .green : .orange)
                    }
                } header: {
                    Text("Auth-Session")
                } footer: {
                    Text("Für den Auth-Gate muss nach dem Abmelden ein neuer Link geöffnet werden. Erst dann gilt der Callback als frisch verifiziert.")
                }

                Section {
                    Button(action: run) {
                        HStack {
                            if isRunning {
                                ProgressView()
                            } else {
                                Image(systemName: "play.fill")
                            }
                            Text(isRunning ? "Hosted E2E läuft …" : "Hosted E2E jetzt prüfen")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)
                    .accessibilityIdentifier("hosted.runSmokeTest")
                } footer: {
                    Text("Der Test legt temporäre Daten an, prüft Import, Review, Confirm, Provenance und Idempotenz und räumt seine Testdaten danach wieder auf.")
                }

                if let report {
                    Section {
                        Label(
                            report.passed ? "Hosted E2E bestanden" : "Hosted E2E fehlgeschlagen",
                            systemImage: report.passed ? "checkmark.seal.fill" : "xmark.octagon.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(report.passed ? .green : .red)

                        Text(report.finishedAt, format: .dateTime.day().month().year().hour().minute().second())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Prüfschritte") {
                        ForEach(report.steps) { step in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: step.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(step.passed ? .green : .red)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.body.weight(.semibold))
                                    Text(step.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                Section {
                    Button("Abmelden & Magic Link neu testen", role: .destructive) {
                        dismiss()
                        signOut()
                    }
                    .accessibilityIdentifier("hosted.signOutForFreshMagicLink")
                } footer: {
                    Text("Danach mit derselben oder einer zweiten echten E-Mail einen neuen Anmeldelink anfordern und direkt auf diesem iPhone öffnen.")
                }
            }
            .navigationTitle("Backend-Diagnose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Login") {
    SupabaseAuthView(errorMessage: .constant(nil))
}
