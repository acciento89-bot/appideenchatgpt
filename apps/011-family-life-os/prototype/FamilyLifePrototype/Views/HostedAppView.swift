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
            Task {
                do {
                    try await SupabaseEnvironment.client.auth.session(from: url)
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

                Section("E-Mail") {
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
            do {
                try await SupabaseEnvironment.client.auth.signInWithOTP(
                    email: trimmed,
                    redirectTo: SupabaseEnvironment.authRedirectURL
                )
                didSend = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }
}

private struct HostedFamilyLoaderView: View {
    @State private var store: DemoStore?
    @State private var errorMessage: String?
    @State private var retryToken = UUID()

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
    }
}

#Preview("Login") {
    SupabaseAuthView(errorMessage: .constant(nil))
}
