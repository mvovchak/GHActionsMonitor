import Foundation
import Combine

@MainActor
class PollingService: ObservableObject {
    @Published var activeRuns: [WorkflowRun] = []
    @Published var lastError: String?

    private var pollingTask: Task<Void, Never>?
    private let apiClient = GitHubAPIClient()
    private var seenFailureIds: Set<Int> = []
    private weak var notificationService: NotificationService?
    private var settingsCancellable: AnyCancellable?

    func start(settings: AppSettings, notificationService: NotificationService) {
        self.notificationService = notificationService

        settingsCancellable = Publishers.CombineLatest(
            settings.$personalAccessToken,
            settings.$repositories
        )
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .sink { [weak self] _, _ in
            guard let self else { return }
            self.restartPolling(settings: settings)
        }

        restartPolling(settings: settings)
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        settingsCancellable = nil
    }

    private func restartPolling(settings: AppSettings) {
        pollingTask?.cancel()
        pollingTask = Task {
            while !Task.isCancelled {
                await poll(settings: settings)
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    private func poll(settings: AppSettings) async {
        let token = settings.personalAccessToken
        let repos = settings.repositories

        guard !token.isEmpty else {
            lastError = "No GitHub token. Open Settings to add one."
            return
        }

        guard !repos.isEmpty else {
            activeRuns = []
            lastError = nil
            return
        }

        var allActive: [WorkflowRun] = []
        var allFailures: [WorkflowRun] = []
        var errors: [String] = []

        let client = apiClient

        await withTaskGroup(of: (active: [WorkflowRun], failures: [WorkflowRun], error: String?).self) { group in
            for repo in repos {
                group.addTask {
                    do {
                        async let active = client.fetchInProgressRuns(for: repo, token: token)
                        async let failures = client.fetchRecentFailures(for: repo, token: token)
                        return (try await active, try await failures, nil)
                    } catch {
                        return ([], [], error.localizedDescription)
                    }
                }
            }
            for await result in group {
                allActive.append(contentsOf: result.active)
                allFailures.append(contentsOf: result.failures)
                if let err = result.error { errors.append(err) }
            }
        }

        activeRuns = allActive.sorted { $0.updatedAt > $1.updatedAt }
        lastError = errors.isEmpty ? nil : errors.joined(separator: "\n")

        processFailures(allFailures)
    }

    private func processFailures(_ runs: [WorkflowRun]) {
        let newFailures = runs.filter { !seenFailureIds.contains($0.id) }
        for run in newFailures {
            seenFailureIds.insert(run.id)
            notificationService?.sendFailureNotification(for: run)
        }
    }
}
