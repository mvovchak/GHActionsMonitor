import SwiftUI

enum PRKind {
    case needsReview, yours, other

    var color: Color {
        switch self {
        case .needsReview: return .orange
        case .yours:       return .blue
        case .other:       return .secondary
        }
    }
}

struct PRRowView: View {
    let pr: PullRequest
    let kind: PRKind
    var reviewDecision: ReviewDecision = .none

    private var isStale: Bool {
        let days = Calendar.current.dateComponents([.day], from: pr.updatedAt, to: Date()).day ?? 0
        return days >= 3
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(kind.color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)
                .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 3) {
                // Title + DRAFT badge + stale indicator
                HStack(alignment: .center, spacing: 6) {
                    Text(pr.title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                        .italic(pr.draft)
                        .opacity(isStale ? 0.55 : 1)
                    if pr.draft {
                        Text("DRAFT")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.6), in: Capsule())
                    }
                    if isStale {
                        Image(systemName: "clock.badge.exclamationmark")
                            .imageScale(.small)
                            .foregroundStyle(.orange)
                    }
                    Spacer(minLength: 0)
                    // Review decision badge
                    if reviewDecision != .none {
                        Image(systemName: reviewDecision.icon)
                            .imageScale(.small)
                            .foregroundStyle(AnyShapeStyle(reviewDecision.color))
                    }
                }

                // Repo name
                Text(pr.repoFullName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                // Number · branch · age
                HStack(spacing: 4) {
                    Text("#\(pr.number)")
                        .foregroundStyle(.tertiary)
                    Text("·").foregroundStyle(.tertiary)
                    Text("\(pr.head.ref) → \(pr.base.ref)")
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer(minLength: 4)
                    Text(pr.age)
                        .foregroundStyle(.tertiary)
                        .layoutPriority(1)
                }
                .font(.caption)

                if kind == .other {
                    Text("@\(pr.user.login)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: pr.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
        .contextMenu {
            Button("Open in Browser") {
                if let url = URL(string: pr.htmlUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Copy Link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(pr.htmlUrl, forType: .string)
            }
        }
    }
}
