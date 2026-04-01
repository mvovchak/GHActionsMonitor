import SwiftUI

@main
struct GHActionsMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(appDelegate.pollingService)
        } label: {
            MenuBarLabel(pollingService: appDelegate.pollingService)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
        }
        .commands {
            CommandGroup(after: .appSettings) {
                Button("Settings…") {
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    DispatchQueue.main.async {
                        NSApp.windows.first { $0.title == "Settings" }?.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var pollingService: PollingService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            if badgeCount > 0 {
                Text("\(badgeCount)")
                    .font(.caption.bold())
                    .foregroundStyle(iconColor)
            }
        }
    }

    private var iconName: String {
        if !pollingService.recentFailures.isEmpty { return "exclamationmark.circle.fill" }
        return "hammer.circle"
    }

    private var iconColor: Color {
        if !pollingService.recentFailures.isEmpty { return .red }
        if !pollingService.activeRuns.isEmpty { return .orange }
        return .primary
    }

    private var badgeCount: Int {
        if !pollingService.recentFailures.isEmpty { return pollingService.recentFailures.count }
        return pollingService.activeRuns.count
    }
}
