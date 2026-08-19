import SwiftUI

struct FamilyView: View {
    @Bindable var store: DemoStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isAddingChild = false
    @State private var childName = ""

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
                            Text("Meine Familie")
                                .font(.title3.bold())
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(store.members.count) Familienmitglieder")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)

                    Button {
                        childName = ""
                        isAddingChild = true
                    } label: {
                        Label("Kind hinzufügen", systemImage: "person.crop.circle.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.isRepositoryBusy)
                    .accessibilityIdentifier("family.addChild")

                    Button {
                    } label: {
                        Label("Erwachsene Person einladen", systemImage: "person.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                    .accessibilityHint("Einladungslinks folgen nach dem Hosted-Login-Vertical-Slice")
                }
                .padding(.vertical, 8)
            } footer: {
                Text("Kinderprofile benötigen im MVP keinen eigenen Login.")
            }

            if let error = store.repositoryErrorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
        .sheet(isPresented: $isAddingChild) {
            NavigationStack {
                Form {
                    Section {
                        TextField("Name", text: $childName)
                            .textContentType(.name)
                            .accessibilityIdentifier("family.childName")
                    } header: {
                        Text("Kinderprofil")
                    } footer: {
                        Text("Das Profil gehört zum Haushalt und erhält noch keinen eigenen Account.")
                    }
                }
                .navigationTitle("Kind hinzufügen")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") {
                            isAddingChild = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Hinzufügen") {
                            let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
                            store.addChild(named: name)
                            isAddingChild = false
                        }
                        .disabled(childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("family.confirmAddChild")
                    }
                }
            }
            .presentationDetents([.medium])
        }
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
