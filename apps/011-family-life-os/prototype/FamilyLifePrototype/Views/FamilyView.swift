import SwiftUI

struct FamilyView: View {
    @Bindable var store: DemoStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.indigo.gradient)
                            Image(systemName: "person.3.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 54, height: 54)
                        .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Familie Berger")
                                .font(.title3.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            Text("4 Familienmitglieder")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Button {
                    } label: {
                        Label("Person einladen", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    .accessibilityHint("Wird mit dem Account-Backend aktiviert")
                }
                .padding(.vertical, 8)
            } footer: {
                Text("Einladungen werden im Prototyp noch nicht versendet.")
            }

            Section("Familie") {
                ForEach(store.members) { member in
                    memberRow(member)
                        .padding(.vertical, 4)
                }
            }

            Section("Berechtigungen") {
                Label("Kinderprofile haben im MVP keinen eigenen Login", systemImage: "shield.lefthalf.filled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Label("Gast-/Betreuerzugriff wird serverseitig eingeschränkt", systemImage: "lock.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Familie")
    }

    @ViewBuilder
    private func memberRow(_ member: FamilyMember) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    MemberAvatar(member: member, size: 42)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(member.name)
                            .font(.body.weight(.semibold))
                        Text(member.role.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(accessSummary(for: member))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(member.name), \(member.role.displayName), \(accessSummary(for: member))")
        } else {
            HStack(spacing: 12) {
                MemberAvatar(member: member, size: 42)
                    .accessibilityHidden(true)

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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(member.name), \(member.role.displayName), \(accessSummary(for: member))")
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

#Preview("Familie – Light") {
    NavigationStack {
        FamilyView(store: DemoStore())
    }
}

#Preview("Familie – Dark") {
    NavigationStack {
        FamilyView(store: DemoStore())
    }
    .preferredColorScheme(.dark)
}

#Preview("Familie – Accessibility") {
    NavigationStack {
        FamilyView(store: DemoStore())
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
