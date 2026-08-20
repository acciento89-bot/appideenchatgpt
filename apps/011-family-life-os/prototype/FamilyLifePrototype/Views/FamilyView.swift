import SwiftUI

struct FamilyView: View {
    @Bindable var store: DemoStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isAddingChild = false
    @State private var childName = ""
    @State private var invite: HouseholdInvite?
    @State private var inviteRole: MemberRole = .adult
    @State private var isCreatingInvite = false
    @State private var editingMember: FamilyMember?
    @State private var inviteError: String?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.indigo.gradient)
                            Image(systemName: "person.3.fill").font(.title2).foregroundStyle(.white)
                        }
                        .frame(width: 54, height: 54)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(store.household?.name ?? "Meine Familie").font(.title3.bold())
                            Text("\(store.members.count) Familienmitglieder")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        childName = ""
                        isAddingChild = true
                    } label: {
                        Label("Kind hinzufügen", systemImage: "person.crop.circle.badge.plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isRepositoryBusy)

                    Menu {
                        Button("Erwachsene Person") { createInvite(role: .adult) }
                        Button("Gast / Betreuung") { createInvite(role: .guest) }
                    } label: {
                        Label(isCreatingInvite ? "Einladung wird erstellt …" : "Person einladen", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCreatingInvite)
                }
                .padding(.vertical, 8)
            } footer: {
                Text("Einladungen sind 7 Tage gültig. Kinderprofile benötigen keinen eigenen Login.")
            }

            if let invite {
                Section("Einladung") {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("\(invite.role.displayName) · gültig bis \(invite.expiresAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "link")
                        Text(invite.url?.absoluteString ?? invite.token)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                        if let url = invite.url {
                            ShareLink(item: url) {
                                Label("Einladung teilen", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }

            if let inviteError {
                Section { Label(inviteError, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red) }
            }

            Section("Familie") {
                ForEach(store.members) { member in
                    Button {
                        editingMember = member
                    } label: {
                        memberRow(member)
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Berechtigungen") {
                Label("Owner verwaltet Familie, Einladungen und Abrechnung", systemImage: "crown.fill")
                Label("Erwachsene verwalten gemeinsame Plan- und Inbox-Daten", systemImage: "person.2.fill")
                Label("Kinder sehen ihr Profil und zugewiesene Familienaufgaben", systemImage: "figure.and.child.holdinghands")
                Label("Gäste / Betreuung sind für eingeschränkten Zugriff vorbereitet", systemImage: "lock.shield")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Familie")
        .refreshable { await store.refreshHosted() }
        .sheet(isPresented: $isAddingChild) { addChildSheet }
        .sheet(item: $editingMember) { member in
            MemberEditorView(store: store, member: member)
        }
    }

    private var addChildSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $childName).textContentType(.name)
                } header: {
                    Text("Kinderprofil")
                } footer: {
                    Text("Das Profil gehört zum Haushalt und benötigt keinen eigenen Account.")
                }
            }
            .navigationTitle("Kind hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { isAddingChild = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        store.addChild(named: childName)
                        isAddingChild = false
                    }
                    .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func memberRow(_ member: FamilyMember) -> some View {
        HStack(spacing: 12) {
            MemberAvatar(member: member, size: 42).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(member.name).font(.body.weight(.semibold)).foregroundStyle(.primary)
                Text(member.role.displayName).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(accessSummary(for: member)).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func accessSummary(for member: FamilyMember) -> String {
        switch member.role {
        case .owner: "Owner"
        case .adult: "Voller Zugriff"
        case .child: "Kinderprofil"
        case .guest: "Eingeschränkt"
        }
    }

    private func createInvite(role: MemberRole) {
        isCreatingInvite = true
        inviteError = nil
        Task {
            do { invite = try await store.createInviteV1(role: role) }
            catch { inviteError = error.localizedDescription }
            isCreatingInvite = false
        }
    }
}

private struct MemberEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: DemoStore
    @State var member: FamilyMember

    var body: some View {
        NavigationStack {
            Form {
                Section("Profil") {
                    TextField("Name", text: $member.name)
                    Picker("Farbe", selection: $member.accent) {
                        ForEach(MemberAccent.allCases, id: \.self) { accent in Text(accent.rawValue.capitalized).tag(accent) }
                    }
                }
                if member.role != .owner {
                    Section("Rolle") {
                        Picker("Rolle", selection: $member.role) {
                            ForEach([MemberRole.adult, .child, .guest], id: \.self) { role in Text(role.displayName).tag(role) }
                        }
                    }
                }
            }
            .navigationTitle("Mitglied")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") {
                        member.name = member.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.updateMemberV1(member)
                        dismiss()
                    }
                    .disabled(member.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
