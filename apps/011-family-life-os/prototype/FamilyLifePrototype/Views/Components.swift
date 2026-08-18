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

    private var itemMembers: [FamilyMember] {
        members.filter { item.memberIDs.contains($0.id) }
    }

    private var displayDate: Date? {
        item.startsAt ?? item.dueAt
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                if let displayDate {
                    Text(displayDate, format: .dateTime.hour().minute())
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                } else {
                    Text("Ganztägig")
                        .font(.caption.weight(.semibold))
                }
            }
            .foregroundStyle(.secondary)
            .frame(width: 58, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(item.kind.tint)
                .frame(width: 4)
                .frame(minHeight: 48)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: item.kind.systemImage)
                        .foregroundStyle(item.kind.tint)
                        .accessibilityHidden(true)

                    Text(item.title)
                        .font(.body.weight(.semibold))
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                }

                HStack(spacing: 8) {
                    if !itemMembers.isEmpty {
                        MemberStack(members: itemMembers)
                        Text(itemMembers.map(\.name).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let location = item.location {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            if showsCompletion, let onToggleCompletion {
                Button(action: onToggleCompletion) {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.isCompleted ? "Als offen markieren" : "Als erledigt markieren")
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct SectionHeader: View {
    let title: String
    var trailing: String?

    var body: some View {
        HStack {
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
