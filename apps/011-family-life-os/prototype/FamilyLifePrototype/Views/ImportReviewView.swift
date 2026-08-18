import SwiftUI

struct ImportReviewView: View {
    @Bindable var store: DemoStore
    @State private var sourceExpanded = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                sourcePreview

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(store.proposals.count) Dinge erkannt")
                        .font(.title2.bold())
                    Text("Bitte kurz prüfen, bevor sie in euren Familienplan übernommen werden.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach($store.proposals) { $proposal in
                    ProposalEditor(
                        proposal: $proposal,
                        members: store.members
                    )
                }
            }
            .padding(20)
            .padding(.bottom, 84)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Import prüfen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Später") {
                    store.isImportReviewPresented = false
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            confirmationBar
        }
    }

    private var sourcePreview: some View {
        DisclosureGroup(isExpanded: $sourceExpanded) {
            if let text = store.selectedSource?.sourceText {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .padding(.top, 10)
            } else {
                Text("Originalquelle ist für diesen Fixture-Eintrag nicht als Text hinterlegt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: store.selectedSource?.kind.systemImage ?? "doc")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                    .frame(width: 38, height: 38)
                    .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.selectedSource?.title ?? "Quelle")
                        .font(.headline)
                    Text("Originalquelle anzeigen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var confirmationBar: some View {
        VStack(spacing: 8) {
            if store.hasBlockingProposal {
                Label("Bitte offene Zuordnung prüfen", systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            Button {
                store.confirmSelectedProposals()
            } label: {
                Text("\(store.includedProposalCount) übernehmen")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(store.includedProposalCount == 0 || store.hasBlockingProposal)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

private struct ProposalEditor: View {
    @Binding var proposal: ActionProposal
    let members: [FamilyMember]

    private var assignedMembers: [FamilyMember] {
        members.filter { proposal.memberIDs.contains($0.id) }
    }

    private var assignmentCandidates: [FamilyMember] {
        if proposal.requiresMemberResolution {
            return members.filter { $0.role == .child }
        }
        return members
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Toggle("Übernehmen", isOn: $proposal.isIncluded)
                    .labelsHidden()

                Label(proposal.kind.displayName, systemImage: proposal.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(proposal.kind.tint)

                Spacer()
            }

            TextField("Titel", text: $proposal.title, axis: .vertical)
                .font(.headline)

            if proposal.startsAt != nil {
                DatePicker(
                    "Beginn",
                    selection: Binding(
                        get: { proposal.startsAt ?? .now },
                        set: { proposal.startsAt = $0 }
                    )
                )

                if proposal.endsAt != nil {
                    DatePicker(
                        "Ende",
                        selection: Binding(
                            get: { proposal.endsAt ?? proposal.startsAt ?? .now },
                            set: { proposal.endsAt = $0 }
                        )
                    )
                }
            }

            if proposal.dueAt != nil {
                DatePicker(
                    proposal.kind == .preparation ? "Erinnerung" : "Fällig",
                    selection: Binding(
                        get: { proposal.dueAt ?? .now },
                        set: { proposal.dueAt = $0 }
                    )
                )
            }

            Menu {
                ForEach(assignmentCandidates) { member in
                    Button {
                        if proposal.requiresMemberResolution {
                            proposal.memberIDs = [member.id]
                            proposal.requiresMemberResolution = false
                        } else if proposal.memberIDs.contains(member.id) {
                            proposal.memberIDs.remove(member.id)
                        } else {
                            proposal.memberIDs.insert(member.id)
                        }
                    } label: {
                        if proposal.memberIDs.contains(member.id) {
                            Label(member.name, systemImage: "checkmark")
                        } else {
                            Text(member.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: proposal.memberIDs.isEmpty ? "person.crop.circle.badge.questionmark" : "person.2.fill")
                    if assignedMembers.isEmpty {
                        Text("Welches Kind?")
                            .fontWeight(.semibold)
                    } else {
                        Text(assignedMembers.map(\.name).joined(separator: ", "))
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(proposal.isReadyToConfirm ? Color.primary : Color.orange)
                .padding(12)
                .background(
                    proposal.isReadyToConfirm ? Color.secondary.opacity(0.08) : Color.orange.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }

            if let location = proposal.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let note = proposal.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(proposal.isIncluded ? 1 : 0.55)
    }
}
