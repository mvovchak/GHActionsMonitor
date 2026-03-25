import SwiftUI

struct RepoRowView: View {
    let repo: Repository
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .foregroundStyle(.secondary)
                .imageScale(.small)
                .frame(width: 16)
            Text(repo.fullName)
                .font(.callout)
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}
