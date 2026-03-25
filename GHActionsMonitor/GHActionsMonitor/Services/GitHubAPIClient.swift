import Foundation

enum GitHubError: LocalizedError {
    case unauthorized
    case rateLimited
    case notFound(String)
    case networkError(Error)
    case decodingError(Error)
    case unknownError(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:          return "Invalid or missing GitHub token"
        case .rateLimited:           return "GitHub API rate limit exceeded"
        case .notFound(let repo):    return "Repo not found: \(repo)"
        case .networkError(let e):   return e.localizedDescription
        case .decodingError(let e):  return "Parse error: \(e.localizedDescription)"
        case .unknownError(let c):   return "GitHub API error (HTTP \(c))"
        }
    }
}

actor GitHubAPIClient {
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: - Actions

    func fetchInProgressRuns(for repo: Repository, token: String) async throws -> [WorkflowRun] {
        var c = URLComponents(string: "https://api.github.com/repos/\(repo.fullName)/actions/runs")!
        c.queryItems = [URLQueryItem(name: "status", value: "in_progress")]
        return try await fetchAll(WorkflowRunsResponse.self, baseURL: c.url!, token: token, repo: repo.fullName)
            .flatMap(\.workflowRuns)
    }

    func fetchRecentFailures(for repo: Repository, token: String) async throws -> [WorkflowRun] {
        var c = URLComponents(string: "https://api.github.com/repos/\(repo.fullName)/actions/runs")!
        c.queryItems = [
            URLQueryItem(name: "status",     value: "completed"),
            URLQueryItem(name: "conclusion", value: "failure"),
        ]
        return try await fetchAll(WorkflowRunsResponse.self, baseURL: c.url!, token: token, repo: repo.fullName)
            .flatMap(\.workflowRuns)
    }

    // MARK: - Actions (write)

    func rerunWorkflow(runId: Int, repoFullName: String, token: String) async throws {
        let url = URL(string: "https://api.github.com/repos/\(repoFullName)/actions/runs/\(runId)/rerun")!
        var request = makeRequest(url: url, token: token)
        request.httpMethod = "POST"

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: request)
        } catch {
            throw GitHubError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw GitHubError.unknownError(-1) }
        switch http.statusCode {
        case 201: break
        case 401, 403: throw GitHubError.unauthorized
        case 404:      throw GitHubError.notFound(repoFullName)
        default:       throw GitHubError.unknownError(http.statusCode)
        }
    }

    // MARK: - Pull Requests

    func fetchOpenPRs(for repo: Repository, token: String) async throws -> [PullRequest] {
        var c = URLComponents(string: "https://api.github.com/repos/\(repo.fullName)/pulls")!
        c.queryItems = [URLQueryItem(name: "state", value: "open")]
        return try await fetchAllPages([PullRequest].self, baseURL: c.url!, token: token, repo: repo.fullName)
    }

    func fetchPRReviews(pr: PullRequest, token: String) async throws -> [PRReview] {
        let url = URL(string: "https://api.github.com/repos/\(pr.repoFullName)/pulls/\(pr.number)/reviews")!
        return try await fetchAllPages([PRReview].self, baseURL: url, token: token, repo: pr.repoFullName)
    }

    // MARK: - Repos

    func fetchUserRepos(token: String) async throws -> [GitHubRepo] {
        var c = URLComponents(string: "https://api.github.com/user/repos")!
        c.queryItems = [
            URLQueryItem(name: "sort",        value: "updated"),
            URLQueryItem(name: "affiliation", value: "owner,collaborator,organization_member"),
        ]
        return try await fetchAllPages([GitHubRepo].self, baseURL: c.url!, token: token, repo: "user/repos")
    }

    // MARK: - User

    func fetchCurrentUserLogin(token: String) async throws -> String {
        struct UserResponse: Decodable { let login: String }
        let url = URL(string: "https://api.github.com/user")!
        return try await fetch(UserResponse.self, url: url, token: token, repo: "user").login
    }

    // MARK: - Private: Pagination

    /// Fetch all pages of an array endpoint (Link header-based pagination).
    private func fetchAllPages<T: Decodable>(_ type: [T].Type, baseURL: URL, token: String, repo: String, perPage: Int = 100) async throws -> [T] {
        var all: [T] = []
        var page = 1
        while true {
            var c = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            var items = (c.queryItems ?? []).filter { $0.name != "page" && $0.name != "per_page" }
            items += [
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "page",     value: "\(page)"),
            ]
            c.queryItems = items
            let results = try await fetchWithRetry([T].self, url: c.url!, token: token, repo: repo)
            all.append(contentsOf: results)
            if results.count < perPage { break }
            page += 1
        }
        return all
    }

    /// Fetch all pages of a wrapped-array endpoint (e.g. WorkflowRunsResponse).
    private func fetchAll<T: Decodable>(_ type: T.Type, baseURL: URL, token: String, repo: String, perPage: Int = 100) async throws -> [T] {
        var all: [T] = []
        var page = 1
        while true {
            var c = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
            var items = (c.queryItems ?? []).filter { $0.name != "page" && $0.name != "per_page" }
            items += [
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "page",     value: "\(page)"),
            ]
            c.queryItems = items
            let result = try await fetchWithRetry(T.self, url: c.url!, token: token, repo: repo)
            all.append(result)
            // WorkflowRunsResponse — stop when the page had fewer runs than perPage
            if let response = result as? WorkflowRunsResponse, response.workflowRuns.count < perPage { break }
            // For other wrapped types, fetch just one page
            else if !(result is WorkflowRunsResponse) { break }
            page += 1
        }
        return all
    }

    // MARK: - Private: Fetch with retry

    private func fetchWithRetry<T: Decodable>(_ type: T.Type, url: URL, token: String, repo: String, attempts: Int = 3) async throws -> T {
        var lastError: Error = GitHubError.unknownError(-1)
        for attempt in 0..<attempts {
            do {
                return try await fetch(type, url: url, token: token, repo: repo)
            } catch GitHubError.networkError(let e) {
                lastError = GitHubError.networkError(e)
                if attempt < attempts - 1 {
                    try? await Task.sleep(for: .seconds(Double(1 << attempt))) // 1s, 2s
                }
            } catch {
                throw error // Non-retryable (auth, 404, decode, etc.)
            }
        }
        throw lastError
    }

    // MARK: - Private: Single fetch

    private func fetch<T: Decodable>(_ type: T.Type, url: URL, token: String, repo: String) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: makeRequest(url: url, token: token))
        } catch {
            throw GitHubError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw GitHubError.unknownError(-1) }

        switch http.statusCode {
        case 200:
            do { return try decoder.decode(T.self, from: data) }
            catch { throw GitHubError.decodingError(error) }
        case 401, 403: throw GitHubError.unauthorized
        case 404:      throw GitHubError.notFound(repo)
        case 429:      throw GitHubError.rateLimited
        default:       throw GitHubError.unknownError(http.statusCode)
        }
    }

    private func makeRequest(url: URL, token: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)",                forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json",   forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28",                    forHTTPHeaderField: "X-GitHub-Api-Version")
        return request
    }
}
