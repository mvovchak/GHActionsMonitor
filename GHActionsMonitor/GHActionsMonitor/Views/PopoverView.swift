import SwiftUI
import Sparkle

enum PopoverTab { case actions, prs }

struct PopoverView: View {
    @EnvironmentObject var pollingService: PollingService
    @ObservedObject private var settings = AppSettings.shared
    @State private var tab: PopoverTab = .actions

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if settings.personalAccessToken.isEmpty {
                setupPrompt
            } else {
                Group {
                    switch tab {
                    case .actions: ActionsView()
                    case .prs:     PRsView()
                    }
                }
                .environmentObject(pollingService)
            }
            if let remaining = pollingService.rateLimitRemaining, remaining < 100 {
                rateLimitWarning(remaining)
            }
        }
        .frame(width: 400, height: 520)
    }

    // MARK: - Rate Limit Warning

    private func rateLimitWarning(_ remaining: Int) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 6) {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.orange)
                    .imageScale(.small)
                Text("GitHub API limit low — \(remaining) requests remaining")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Setup Prompt

    private var setupPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                Text("GitHub token required")
                    .font(.headline)
                Text("Add a Personal Access Token with\n**repo** and **workflow** scopes to get started.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Open Settings") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                DispatchQueue.main.async {
                    NSApp.windows.first { $0.title == "Settings" }?.makeKeyAndOrderFront(nil)
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 4) {
            TabButton(
                label: "Actions",
                icon: "hammer.circle.fill",
                count: pollingService.activeRuns.count,
                countColor: .orange,
                isSelected: tab == .actions
            ) { tab = .actions }

            TabButton(
                label: "Pull Requests",
                icon: "arrow.triangle.pull",
                count: pollingService.openPRs.count,
                countColor: .blue,
                isSelected: tab == .prs
            ) { tab = .prs }

            Spacer()

            Button {
                NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
            } label: {
                Image(systemName: "arrow.clockwise.circle")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Check for Updates…")

            Button {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                DispatchQueue.main.async {
                    NSApp.windows.first { $0.title == "Settings" }?.makeKeyAndOrderFront(nil)
                }
            } label: {
                Image(systemName: "gear")
                    .imageScale(.medium)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let label: String
    let icon: String
    let count: Int
    let countColor: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .imageScale(.small)
                Text(label)
                    .font(.subheadline)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSelected ? .white : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? countColor : Color.secondary.opacity(0.25),
                            in: Capsule()
                        )
                }
            }
            .foregroundStyle(isSelected ? countColor : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                isSelected ? countColor.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
            )
        }
        .buttonStyle(.plain)
    }
}
