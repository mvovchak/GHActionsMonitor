import SwiftUI

struct ActionsView: View {
    @EnvironmentObject var pollingService: PollingService
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        if pollingService.activeRuns.isEmpty && pollingService.recentFailures.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !pollingService.activeRuns.isEmpty {
                        ActionsSectionHeader(title: "RUNNING", count: pollingService.activeRuns.count, color: .orange)
                        ForEach(pollingService.activeRuns) { run in
                            RunRowView(run: run)
                            Divider().padding(.leading, 44)
                        }
                    }

                    if !pollingService.recentFailures.isEmpty {
                        ActionsSectionHeader(title: "RECENT FAILURES", count: pollingService.recentFailures.count, color: .red)
                        ForEach(pollingService.recentFailures) { run in
                            RunRowView(run: run)
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }

        if let error = pollingService.lastError,
           !pollingService.activeRuns.isEmpty || !pollingService.recentFailures.isEmpty {
            errorFooter(error)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            if settings.repositories.isEmpty {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No repositories watched")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Add in Settings") { openSettings() }
                    .font(.callout)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
            } else if let error = pollingService.lastError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("No running workflows or recent failures")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        DispatchQueue.main.async {
            NSApp.windows.first { $0.title == "Settings" }?.makeKeyAndOrderFront(nil)
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

struct ActionsSectionHeader: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(color.opacity(0.8), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }
}
