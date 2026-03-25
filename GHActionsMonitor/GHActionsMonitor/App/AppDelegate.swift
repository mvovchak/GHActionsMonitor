import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = AppSettings.shared
    let pollingService = PollingService()
    let notificationService = NotificationService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Task { await notificationService.requestAuthorization() }
        pollingService.start(settings: settings, notificationService: notificationService)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
