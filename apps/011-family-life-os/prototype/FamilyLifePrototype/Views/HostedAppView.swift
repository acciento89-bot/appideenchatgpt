import Supabase
import SwiftUI

struct HostedAppView: View {
    @State private var isAuthenticated = false
    @State private var hasReceivedInitialAuthState = false
    @State private var authErrorMessage: String?

    var body: some View {
        Group {
            if !hasReceivedInitialAuthState {
                ProgressView("Session wird geprüft …")
            } else if isAuthenticated {
                HostedFamilyLoaderView()
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
                    if state.session != nil {
                        authErrorMessage = nil
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
                    _ = try await SupabaseEnvironment.client.auth.session(from: url)
                    isAuthenticated = true
                    hasReceivedInitialAuthState = true
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
                        Task {
                            try? await SupabaseEnvironment.client.auth.signOut()
                        }
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
                isRunning: isRunningSmokeTest,
                report: smokeReport,
                run: runSmokeTest
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
}

private struct HostedDiagnosticsView: View {
    @Environment(\.dismiss) private var dismiss

    let isRunning: Bool
    let report: HostedSmokeTestReport?
    let run: () -> Void

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
