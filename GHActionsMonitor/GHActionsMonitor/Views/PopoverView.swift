import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var pollingService: PollingService
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            if let error = pollingService.lastError, !pollingService.activeRuns.isEmpty {
                errorFooter(error)
            }
        }
        .frame(width: 380, height: 500)
    }

    private var header: some View {
        HStack {
            Text("GitHub Actions")
                .font(.headline)
            Spacer()
            Button(action: { openSettings() }) {
                Image(systemName: "gear")
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if pollingService.activeRuns.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(pollingService.activeRuns) { run in
                        RunRowView(run: run)
                        Divider().padding(.leading, 44)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            if let error = pollingService.lastError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Open Settings") { openSettings() }
                    .padding(.top, 4)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("No running workflows")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func errorFooter(_ error: String) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .imageScale(.small)
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }
}
