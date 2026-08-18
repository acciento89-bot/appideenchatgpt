import SwiftUI

struct FamilyView: View {
    @Bindable var store: DemoStore

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.indigo.gradient)
                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Familie Berger")
                                .font(.title3.bold())
                            Text("4 Familienmitglieder")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                    } label: {
                        Label("Person einladen", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }

            Section("Familie") {
                ForEach(store.members) { member in
                    HStack(spacing: 12) {
                        MemberAvatar(member: member, size: 42)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(member.name)
                                .font(.body.weight(.semibold))
                            Text(member.role.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(accessSummary(for: member))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Berechtigungen") {
                Label("Kinderprofile haben im MVP keinen eigenen Login", systemImage: "shield.lefthalf.filled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label("Gast-/Betreuerzugriff wird serverseitig eingeschränkt", systemImage: "lock.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Familie")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Familieneinstellungen")
            }
        }
    }

    private func accessSummary(for member: FamilyMember) -> String {
        switch member.role {
        case .owner, .adult:
            "Voller Zugriff"
        case .child:
            "Profil ohne Login"
        case .guest:
            "Eingeschränkt"
        }
    }
}
