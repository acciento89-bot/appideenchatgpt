import SwiftUI

extension MemberAccent {
    var color: Color {
        switch self {
        case .indigo: .indigo
        case .teal: .teal
        case .orange: .orange
        case .purple: .purple
        }
    }
}

extension InboxStatus {
    var tint: Color {
        switch self {
        case .queued: .gray
        case .uploading, .processing: .blue
        case .review, .partial: .orange
        case .done: .green
        case .failed: .red
        }
    }
}

extension PlanKind {
    var tint: Color {
        switch self {
        case .event: .blue
        case .task: .teal
        case .deadline: .orange
        case .payment: .indigo
        case .preparation: .purple
        }
    }
}

struct MemberAvatar: View {
    let member: FamilyMember
    var size: CGFloat = 32

    var body: some View {
        Text(member.initials)
            .font(.system(size: max(11, size * 0.34), weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(member.accent.color.gradient, in: Circle())
            .accessibilityLabel(member.name)
    }
}

struct MemberStack: View {
    let members: [FamilyMember]

    var body: some View {
        HStack(spacing: -6) {
            ForEach(members.prefix(3)) { member in
                MemberAvatar(member: member, size: 26)
                    .overlay {
                        Circle().stroke(.background, lineWidth: 2)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

struct StatusPill: View {
    let status: InboxStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

struct AgendaRow: View {
    let item: PlanItem
    let members: [FamilyMember]
    var showsCompletion = false
    var onToggleCompletion: (() -> Void)?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var itemMembers: [FamilyMember] {
        members.filter { item.memberIDs.contains($0.id) }
    }

    private var displayDate: Date? {
        item.startsAt ?? item.dueAt
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                standardLayout
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            timeLabel
                .frame(width: 58, alignment: .leading)

            kindMarker
            coreContent
            Spacer(minLength: 4)
            completionButton
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                timeLabel
                Spacer(minLength: 8)
                completionButton
            }

            HStack(alignment: .top, spacing: 10) {
                kindMarker
                coreContent
            }
        }
    }

    private var timeLabel: some View {
        Group {
            if let displayDate {
                Text(displayDate, format: .dateTime.hour().minute())
                    .font(.subheadline.monospacedDigit().weight(.semibold))
            } else {
                Text("Ganztägig")
                    .font(.caption.weight(.semibold))
            }
        }
        .foregroundStyle(.secondary)
    }

    private var kindMarker: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(item.kind.tint)
            .frame(width: 4)
            .frame(minHeight: 48)
            .accessibilityHidden(true)
    }

    private var coreContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                Image(systemName: item.kind.systemImage)
                    .foregroundStyle(item.kind.tint)
                    .accessibilityHidden(true)

                Text(item.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !itemMembers.isEmpty {
                HStack(spacing: 8) {
                    MemberStack(members: itemMembers)
                    Text(itemMembers.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let location = item.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var completionButton: some View {
        if showsCompletion, let onToggleCompletion {
            Button(action: onToggleCompletion) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")
            .accessibilityIdentifier("plan-item-completion")
        }
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize, let trailing {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.title3.bold())
                    Text(trailing)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.title3.bold())
                    Spacer()
                    if let trailing {
                        Text(trailing)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
