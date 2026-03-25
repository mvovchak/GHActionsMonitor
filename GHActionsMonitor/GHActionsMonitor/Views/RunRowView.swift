import SwiftUI

struct RunRowView: View {
    let run: WorkflowRun
    @EnvironmentObject var pollingService: PollingService

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .padding(.leading, 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(run.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text([run.repository.fullName, run.headBranch].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(run.statusDisplay)
                    .font(.caption)
                    .foregroundStyle(statusColor)
                Text(run.duration)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: run.htmlUrl) {
                NSWorkspace.shared.open(url)
            }
        }
        .contextMenu {
            Button("Open in Browser") {
                if let url = URL(string: run.htmlUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Copy Link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(run.htmlUrl, forType: .string)
            }
            if run.conclusion == "failure" {
                Divider()
                Button("Re-run Workflow") {
                    Task { await pollingService.rerunWorkflow(run: run) }
                }
            }
        }
    }

    private var statusColor: Color {
        switch run.status {
        case "in_progress":
            return .orange
        case "completed":
            switch run.conclusion {
            case "failure":   return .red
            case "success":   return .green
            case "cancelled": return .gray
            default:          return .secondary
            }
        default:
            return .secondary
        }
    }
}
