import AppKit
import SwiftUI
import Sparkle

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings.shared
    let pollingService = PollingService()
    let notificationService = NotificationService()
    private(set) var updaterController: SPUStandardUpdaterController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        Task { await notificationService.requestAuthorization() }
        pollingService.start(settings: settings, notificationService: notificationService)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
