import Foundation
import Combine

@MainActor
class PollingService: ObservableObject {
    @Published var activeRuns: [WorkflowRun] = []
    @Published var recentFailures: [WorkflowRun] = []
    @Published var openPRs: [PullRequest] = []
    @Published var prReviewDecisions: [Int: ReviewDecision] = [:]
    @Published var currentUserLogin: String = ""
    @Published var rateLimitRemaining: Int? = nil
    @Published var lastError: String?

    private var pollingTask: Task<Void, Never>?
    private let apiClient = GitHubAPIClient()
    private var seenFailureIds: Set<Int> = []
    private var seenReviewRequestedPRIds: Set<Int> = []
    private var seenPRReviewDecisions: [Int: ReviewDecision] = [:]
    private var hasCompletedFirstPoll = false
    private var lastKnownToken: String = ""
    private weak var notificationService: NotificationService?
    private var settings: AppSettings?
    private var settingsCancellable: AnyCancellable?

    func start(settings: AppSettings, notificationService: NotificationService) {
        self.settings = settings
        self.notificationService = notificationService

        settingsCancellable = Publishers.CombineLatest(
            settings.$personalAccessToken,
            settings.$repositories
        )
        .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
        .sink { [weak self] newToken, _ in
            guard let self else { return }
            let tokenChanged = newToken != self.lastKnownToken
            self.lastKnownToken = newToken
            self.restartPolling(clearSeenState: tokenChanged)
        }

        lastKnownToken = settings.personalAccessToken
        restartPolling(clearSeenState: true)
    }

    func stop() {
        pollingTask?.cancel()
        pollingTask = nil
        settingsCancellable = nil
    }

    func rerunWorkflow(run: WorkflowRun) async {
        guard let token = settings?.personalAccessToken, !token.isEmpty else { return }
        try? await apiClient.rerunWorkflow(runId: run.id, repoFullName: run.repository.fullName, token: token)
    }

    private func restartPolling(clearSeenState: Bool = false) {
        pollingTask?.cancel()
        hasCompletedFirstPoll = false
        if clearSeenState {
            seenFailureIds = []
            seenReviewRequestedPRIds = []
            seenPRReviewDecisions = [:]
            currentUserLogin = ""
        }
        pollingTask = Task {
            while !Task.isCancelled {
                let start = Date()
                await poll()
                let elapsed = Date().timeIntervalSince(start)
                let interval = Double(settings?.pollIntervalSeconds ?? 60)
                let remaining = max(5, interval - elapsed)
                try? await Task.sleep(for: .seconds(remaining))
            }
        }
    }

    private func poll() async {
        guard let settings else { return }
        let token = settings.personalAccessToken
        let repos = settings.repositories

        guard !token.isEmpty else {
            lastError = "No GitHub token. Open Settings to add one."
            return
        }

        if currentUserLogin.isEmpty {
            currentUserLogin = (try? await apiClient.fetchCurrentUserLogin(token: token)) ?? ""
        }

        guard !repos.isEmpty else {
            activeRuns = []
            recentFailures = []
            openPRs = []
            prReviewDecisions = [:]
            lastError = nil
            return
        }

        var allActive: [WorkflowRun] = []
        var allFailures: [WorkflowRun] = []
        var allPRs: [PullRequest] = []
        var errors: [String] = []

        let client = apiClient

        await withTaskGroup(of: (active: [WorkflowRun], failures: [WorkflowRun], prs: [PullRequest], error: String?).self) { group in
            for repo in repos {
                group.addTask {
                    do {
                        async let active   = client.fetchInProgressRuns(for: repo, token: token)
                        async let failures = client.fetchRecentFailures(for: repo, token: token)
                        async let prs      = client.fetchOpenPRs(for: repo, token: token)
                        return (try await active, try await failures, try await prs, nil)
                    } catch {
                        return ([], [], [], error.localizedDescription)
                    }
                }
            }
            for await result in group {
                allActive.append(contentsOf: result.active)
                allFailures.append(contentsOf: result.failures)
                allPRs.append(contentsOf: result.prs)
                if let err = result.error { errors.append(err) }
            }
        }

        // Fetch PR reviews concurrently
        var decisions: [Int: ReviewDecision] = [:]
        await withTaskGroup(of: (Int, ReviewDecision).self) { group in
            for pr in allPRs {
                group.addTask {
                    let reviews = (try? await client.fetchPRReviews(pr: pr, token: token)) ?? []
                    let decision = ReviewDecision.compute(from: reviews, prAuthor: pr.user.login)
                    return (pr.id, decision)
                }
            }
            for await (prId, decision) in group {
                decisions[prId] = decision
            }
        }

        activeRuns        = allActive.sorted { $0.updatedAt > $1.updatedAt }
        recentFailures    = allFailures.sorted { $0.updatedAt > $1.updatedAt }
        openPRs           = allPRs.sorted { $0.updatedAt > $1.updatedAt }
        prReviewDecisions = decisions
        rateLimitRemaining = await client.rateLimitRemaining
        lastError         = errors.isEmpty ? nil : errors.joined(separator: "\n")

        processFailures(allFailures)
        processReviews(allPRs, decisions: decisions)
    }

    private func processFailures(_ runs: [WorkflowRun]) {
        guard hasCompletedFirstPoll else {
            runs.forEach { seenFailureIds.insert($0.id) }
            return
        }
        let newFailures = runs.filter { !seenFailureIds.contains($0.id) }
        for run in newFailures {
            seenFailureIds.insert(run.id)
            notificationService?.sendFailureNotification(for: run)
        }
    }

    private func processReviews(_ prs: [PullRequest], decisions: [Int: ReviewDecision]) {
        let login = currentUserLogin
        guard !login.isEmpty else {
            hasCompletedFirstPoll = true
            return
        }

        let reviewRequestedPRs = prs.filter { $0.requestedReviewers.map(\.login).contains(login) }
        let myPRs = prs.filter { $0.user.login == login }

        if hasCompletedFirstPoll {
            for pr in reviewRequestedPRs where !seenReviewRequestedPRIds.contains(pr.id) {
                notificationService?.sendReviewRequestedNotification(for: pr)
            }
            for pr in myPRs {
                let newDecision = decisions[pr.id] ?? .none
                let oldDecision = seenPRReviewDecisions[pr.id] ?? .none
                if newDecision != oldDecision {
                    switch newDecision {
                    case .approved:         notificationService?.sendPRApprovedNotification(for: pr)
                    case .changesRequested: notificationService?.sendChangesRequestedNotification(for: pr)
                    case .none:             break
                    }
                }
            }
        }

        seenReviewRequestedPRIds = Set(reviewRequestedPRs.map(\.id))
        for pr in myPRs {
            seenPRReviewDecisions[pr.id] = decisions[pr.id] ?? .none
        }
        hasCompletedFirstPoll = true
    }
}
