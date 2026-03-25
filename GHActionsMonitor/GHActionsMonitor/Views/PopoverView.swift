import SwiftUI
import Sparkle

enum PopoverTab { case actions, prs }

struct PopoverView: View {
    @EnvironmentObject var pollingService: PollingService
    @State private var tab: PopoverTab = .actions

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            Group {
                switch tab {
                case .actions: ActionsView()
                case .prs:     PRsView()
                }
            }
            .environmentObject(pollingService)
        }
        .frame(width: 400, height: 520)
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

            SettingsLink {
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
