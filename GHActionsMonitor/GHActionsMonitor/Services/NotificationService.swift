import UserNotifications

class NotificationService {
    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    func sendFailureNotification(for run: WorkflowRun) {
        let content = UNMutableNotificationContent()
        content.title = "Workflow Failed"
        content.subtitle = run.repository.fullName
        content.body = "\(run.name) on \(run.headBranch)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "failure-\(run.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
