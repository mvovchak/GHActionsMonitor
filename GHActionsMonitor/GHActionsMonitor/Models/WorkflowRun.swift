import Foundation

struct WorkflowRun: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let headBranch: String?
    let status: String
    let conclusion: String?
    let htmlUrl: String
    let updatedAt: Date
    let repository: RunRepository

    enum CodingKeys: String, CodingKey {
        case id, name, status, conclusion
        case headBranch = "head_branch"
        case htmlUrl = "html_url"
        case updatedAt = "updated_at"
        case repository
    }

    var duration: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: updatedAt, to: Date())
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0
        if hours > 0 { return "\(hours)h \(minutes)m" }
        if minutes > 0 { return "\(minutes)m" }
        return "< 1m"
    }

    var statusDisplay: String {
        switch status {
        case "in_progress": return "Running"
        case "completed":
            switch conclusion {
            case "failure":   return "Failed"
            case "success":   return "Passed"
            case "cancelled": return "Cancelled"
            case "skipped":   return "Skipped"
            default:          return conclusion?.capitalized ?? "Completed"
            }
        case "queued":  return "Queued"
        case "waiting": return "Waiting"
        default:        return status.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

struct RunRepository: Codable, Sendable {
    let fullName: String
    enum CodingKeys: String, CodingKey { case fullName = "full_name" }
}

struct WorkflowRunsResponse: Codable {
    let workflowRuns: [WorkflowRun]
    enum CodingKeys: String, CodingKey { case workflowRuns = "workflow_runs" }
}
