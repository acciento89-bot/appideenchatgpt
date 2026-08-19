import SwiftUI

struct FamilyManagementV1View: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore

    @State private var invite: HouseholdInvite?
    @State private var inviteRole: MemberRole = .adult
    @State private var inviteError: String?
    @State private var selectedMember: FamilyMember?

    var body: some View {
        NavigationStack {
            List {
                Section("Familie") {
                    ForEach(store.members) { member in
                        Button {
                            selectedMember = member
                        } label: {
                            HStack(spacing: 12) {
                                MemberAvatar(member: member, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name).font(.body.weight(.semibold))
                                    Text(member.role.displayName).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Einladen") {
                    Picker("Rolle", selection: $inviteRole) {
                        Text("Erwachsen").tag(MemberRole.adult)
                        Text("Gast / Betreuung").tag(MemberRole.guest)
                    }

                    Button {
                        Task {
                            do {
                                invite = try await store.createInviteV1(role: inviteRole)
                                inviteError = nil
                            } catch { inviteError = error.localizedDescription }
                        }
                    } label: {
                        Label("Sicheren Einladungslink erstellen", systemImage: "person.badge.plus")
                    }

                    if let invite {
                        ShareLink(item: invite.shareURL) {
                            Label("Einladung teilen", systemImage: "square.and.arrow.up")
                        }
                        Text("Gültig bis \(invite.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Einladungen laufen automatisch ab. Der geheime Token wird serverseitig nur gehasht gespeichert.")
                }

                if let inviteError {
                    Section { Text(inviteError).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Familie verwalten")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } }
            }
            .sheet(item: $selectedMember) { member in
                MemberEditorV1View(store: store, member: member)
            }
        }
    }
}

private struct MemberEditorV1View: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    @State private var member: FamilyMember

    init(store: DemoStore, member: FamilyMember) {
        self.store = store
        _member = State(initialValue: member)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Name", text: $member.name)
                    Picker("Farbe", selection: $member.accent) {
                        ForEach(MemberAccent.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }

                Section("Rolle") {
                    Picker("Zugriff", selection: $member.role) {
                        ForEach(MemberRole.allCases, id: \.self) { Text($0.displayName).tag($0) }
                    }
                    Text(accessText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(member.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        store.updateMemberV1(member)
                        dismiss()
                    }
                    .disabled(member.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var accessText: String {
        switch member.role {
        case .owner: "Owner verwaltet Haushalt, Rollen und Abrechnung."
        case .adult: "Erwachsene verwalten gemeinsame Familieninhalte."
        case .child: "Kinder sehen und erledigen zugewiesene Inhalte; keine Verwaltung oder Abrechnung."
        case .guest: "Gastzugriff ist eingeschränkt und für Betreuung/Verwandte vorgesehen."
        }
    }
}
