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
    }
}

struct MenuBarLabel: View {
    @ObservedObject var pollingService: PollingService

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "hammer.circle")
            if pollingService.activeRuns.count > 0 {
                Text("\(pollingService.activeRuns.count)")
                    .font(.caption.bold())
            }
        }
    }
}
