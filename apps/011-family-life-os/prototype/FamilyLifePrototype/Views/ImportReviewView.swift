import SwiftUI

struct ImportReviewView: View {
    @Bindable var store: DemoStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var sourceExpanded = false

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularWidthLayout
            } else {
                compactWidthLayout
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Import prüfen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Später") {
                    store.isImportReviewPresented = false
                }
                .accessibilityHint("Schließt die Prüfung, ohne die Quelle zu löschen")
            }
        }
        .safeAreaInset(edge: .bottom) {
            confirmationBar
        }
    }

    private var compactWidthLayout: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                sourcePreview
                extractionHeader
                proposalCards
            }
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(20)
            .padding(.bottom, 84)
        }
    }

    private var regularWidthLayout: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Original")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    sourcePreview
                }
                .padding(24)
            }
            .frame(minWidth: 300, idealWidth: 360, maxWidth: 420)
            .background(Color(.secondarySystemGroupedBackground))

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    extractionHeader
                    proposalCards
                }
                .frame(maxWidth: 700, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(24)
                .padding(.bottom, 84)
            }
        }
    }

    private var extractionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(store.proposals.count) Dinge erkannt")
                .font(.title2.bold())
            Text("Bitte kurz prüfen, bevor sie in euren Familienplan übernommen werden.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var proposalCards: some View {
        ForEach($store.proposals) { $proposal in
            ProposalEditor(
                proposal: $proposal,
                members: store.members
            )
        }
    }

    private var sourcePreview: some View {
        DisclosureGroup(isExpanded: $sourceExpanded) {
            if let text = store.selectedSource?.sourceText {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            } else {
                Text("Originalquelle ist für diesen Eintrag nicht als Text hinterlegt.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: store.selectedSource?.kind.systemImage ?? "doc")
                    .font(.title3)
                    .foregroundStyle(.indigo)
                    .frame(width: 38, height: 38)
                    .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(store.selectedSource?.title ?? "Quelle")
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(sourceExpanded ? "Originalquelle ausblenden" : "Originalquelle anzeigen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityIdentifier("import-source")
    }

    private var confirmationBar: some View {
        VStack(spacing: 8) {
            if store.hasBlockingProposal {
                Label("Bitte offene Angaben prüfen", systemImage: "exclamationmark.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .accessibilityIdentifier("import-blocker")
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
            .accessibilityHint(store.hasBlockingProposal ? "Erst offene Pflichtfelder prüfen" : "Übernimmt die ausgewählten Vorschläge in den Familienplan")
            .accessibilityIdentifier("import-confirm")
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

private struct ProposalEditor: View {
    @Binding var proposal: ActionProposal
    let members: [FamilyMember]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var assignedMembers: [FamilyMember] {
        members.filter { proposal.memberIDs.contains($0.id) }
    }

    private var memberNeedsResolution: Bool {
        proposal.requiresMemberResolution || proposal.unresolvedFields["member"] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                Toggle("Übernehmen", isOn: $proposal.isIncluded)
                    .labelsHidden()
                    .accessibilityLabel("Vorschlag übernehmen")

                Label(proposal.kind.displayName, systemImage: proposal.kind.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(proposal.kind.tint)

                Spacer(minLength: 0)
            }

            TextField("Titel", text: $proposal.title, axis: .vertical)
                .font(.headline)
                .accessibilityLabel("Titel")

            timingControls
            assignmentControl

            if !proposal.unresolvedFields.isEmpty {
                Label(
                    "Noch offen: \(proposal.unresolvedDisplayNames.joined(separator: ", "))",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("proposal-unresolved")
            }

            if let location = proposal.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let note = proposal.note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(proposal.isIncluded ? 1 : 0.55)
        .accessibilityIdentifier("proposal-\(proposal.id.uuidString)")
    }

    @ViewBuilder
    private var timingControls: some View {
        if proposal.unresolvedFields["starts_at"] != nil {
            requiredDateControl(
                title: "Datum und Uhrzeit festlegen",
                date: Binding(
                    get: { proposal.startsAt ?? .now },
                    set: {
                        proposal.startsAt = $0
                        proposal.resolveUncertainty("starts_at")
                        proposal.resolveUncertainty("time")
                    }
                ),
                components: [.date, .hourAndMinute]
            )
        } else if let start = proposal.startsAt {
            if proposal.unresolvedFields["time"] != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Datum erkannt: \(start.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    requiredDateControl(
                        title: "Uhrzeit festlegen",
                        date: Binding(
                            get: { proposal.startsAt ?? start },
                            set: {
                                proposal.startsAt = $0
                                proposal.resolveUncertainty("time")
                            }
                        ),
                        components: .hourAndMinute
                    )
                }
            } else {
                dateControl(
                    title: "Beginn",
                    date: Binding(
                        get: { proposal.startsAt ?? start },
                        set: { proposal.startsAt = $0 }
                    )
                )
            }

            if proposal.endsAt != nil {
                dateControl(
                    title: "Ende",
                    date: Binding(
                        get: { proposal.endsAt ?? proposal.startsAt ?? .now },
                        set: { proposal.endsAt = $0 }
                    )
                )
            }
        }

        if proposal.unresolvedFields["due_at"] != nil {
            requiredDateControl(
                title: proposal.kind == .preparation ? "Vorbereitung festlegen" : "Fälligkeit festlegen",
                date: Binding(
                    get: { proposal.dueAt ?? .now },
                    set: {
                        proposal.dueAt = $0
                        proposal.resolveUncertainty("due_at")
                    }
                ),
                components: [.date, .hourAndMinute]
            )
        } else if proposal.dueAt != nil {
            dateControl(
                title: proposal.kind == .preparation ? "Erinnerung" : "Fällig",
                date: Binding(
                    get: { proposal.dueAt ?? .now },
                    set: { proposal.dueAt = $0 }
                )
            )
        }
    }

    private var assignmentControl: some View {
        Menu {
            ForEach(members) { member in
                Button {
                    if memberNeedsResolution {
                        proposal.memberIDs = [member.id]
                        proposal.resolveUncertainty("member")
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
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: assignedMembers.isEmpty ? "person.crop.circle.badge.questionmark" : "person.2.fill")
                    .accessibilityHidden(true)
                if assignedMembers.isEmpty {
                    Text(memberNeedsResolution ? "Person zuordnen" : "Keine Zuordnung")
                        .fontWeight(memberNeedsResolution ? .semibold : .regular)
                } else {
                    Text(assignedMembers.map(\.name).joined(separator: ", "))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(memberNeedsResolution && assignedMembers.isEmpty ? Color.orange : Color.primary)
            .padding(12)
            .background(
                memberNeedsResolution && assignedMembers.isEmpty ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .accessibilityLabel(
            assignedMembers.isEmpty
                ? (memberNeedsResolution ? "Person zuordnen, noch offen" : "Keine Person zugeordnet")
                : "Zugeordnet zu \(assignedMembers.map(\.name).joined(separator: ", "))"
        )
        .accessibilityHint("Öffnet die Auswahl der Familienmitglieder")
    }

    @ViewBuilder
    private func requiredDateControl(
        title: String,
        date: Binding<Date>,
        components: DatePickerComponents
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "exclamationmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
            DatePicker(title, selection: date, displayedComponents: components)
                .labelsHidden()
                .datePickerStyle(.compact)
                .accessibilityLabel(title)
        }
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func dateControl(title: String, date: Binding<Date>) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                DatePicker(title, selection: date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .accessibilityLabel(title)
            }
        } else {
            DatePicker(title, selection: date)
                .datePickerStyle(.compact)
        }
    }
}

#Preview("Import prüfen – iPhone") {
    let store = DemoStore()
    store.openSignatureReview()
    return NavigationStack {
        ImportReviewView(store: store)
    }
}

#Preview("Import prüfen – bereit") {
    let store = DemoStore(scenario: .readyImport)
    store.openSignatureReview()
    return NavigationStack {
        ImportReviewView(store: store)
    }
}

#Preview("Import prüfen – Dark") {
    let store = DemoStore()
    store.openSignatureReview()
    return NavigationStack {
        ImportReviewView(store: store)
    }
    .preferredColorScheme(.dark)
}

#Preview("Import prüfen – Accessibility") {
    let store = DemoStore()
    store.openSignatureReview()
    return NavigationStack {
        ImportReviewView(store: store)
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}

#Preview("Import prüfen – Regular Width") {
    let store = DemoStore()
    store.openSignatureReview()
    return NavigationStack {
        ImportReviewView(store: store)
    }
    .environment(\.horizontalSizeClass, .regular)
}
