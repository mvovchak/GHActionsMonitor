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
        content.body = run.headBranch.map { "\(run.name) on \($0)" } ?? run.name
        content.sound = .default
        deliver("failure-\(run.id)", content: content)
    }

    func sendReviewRequestedNotification(for pr: PullRequest) {
        let content = UNMutableNotificationContent()
        content.title = "Review Requested"
        content.subtitle = pr.repoFullName
        content.body = pr.title
        content.sound = .default
        deliver("review-requested-\(pr.id)", content: content)
    }

    func sendPRApprovedNotification(for pr: PullRequest) {
        let content = UNMutableNotificationContent()
        content.title = "PR Approved"
        content.subtitle = pr.repoFullName
        content.body = pr.title
        content.sound = .default
        deliver("pr-approved-\(pr.id)", content: content)
    }

    func sendChangesRequestedNotification(for pr: PullRequest) {
        let content = UNMutableNotificationContent()
        content.title = "Changes Requested"
        content.subtitle = pr.repoFullName
        content.body = pr.title
        content.sound = .default
        deliver("changes-requested-\(pr.id)", content: content)
    }

    private func deliver(_ identifier: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
