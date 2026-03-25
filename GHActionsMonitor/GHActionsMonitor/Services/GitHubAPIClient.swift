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

    func fetchInProgressRuns(for repo: Repository, token: String) async throws -> [WorkflowRun] {
        var components = URLComponents(string: "https://api.github.com/repos/\(repo.fullName)/actions/runs")!
        components.queryItems = [URLQueryItem(name: "status", value: "in_progress")]
        return try await fetchRuns(url: components.url!, token: token, repo: repo)
    }

    func fetchRecentFailures(for repo: Repository, token: String) async throws -> [WorkflowRun] {
        var components = URLComponents(string: "https://api.github.com/repos/\(repo.fullName)/actions/runs")!
        components.queryItems = [
            URLQueryItem(name: "status", value: "completed"),
            URLQueryItem(name: "conclusion", value: "failure"),
            URLQueryItem(name: "per_page", value: "10")
        ]
        return try await fetchRuns(url: components.url!, token: token, repo: repo)
    }

    private func fetchRuns(url: URL, token: String, repo: Repository) async throws -> [WorkflowRun] {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GitHubError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GitHubError.unknownError(-1)
        }

        switch http.statusCode {
        case 200:
            do {
                return try decoder.decode(WorkflowRunsResponse.self, from: data).workflowRuns
            } catch {
                throw GitHubError.decodingError(error)
            }
        case 401, 403: throw GitHubError.unauthorized
        case 404:      throw GitHubError.notFound(repo.fullName)
        case 429:      throw GitHubError.rateLimited
        default:       throw GitHubError.unknownError(http.statusCode)
        }
    }
}
