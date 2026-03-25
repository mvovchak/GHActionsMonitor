import Foundation

struct PullRequest: Codable, Identifiable, Sendable {
    let id: Int
    let number: Int
    let title: String
    let draft: Bool
    let htmlUrl: String
    let createdAt: Date
    let updatedAt: Date
    let user: PRUser
    let head: PRBranch
    let base: PRBranch
    let requestedReviewers: [PRUser]

    enum CodingKeys: String, CodingKey {
        case id, number, title, draft
        case htmlUrl = "html_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user, head, base
        case requestedReviewers = "requested_reviewers"
    }

    var repoFullName: String {
        // Parse from "https://github.com/owner/repo/pull/42"
        let parts = htmlUrl.split(separator: "/")
        guard parts.count >= 5 else { return "" }
        return "\(parts[2])/\(parts[3])"
    }

    var age: String {
        let comps = Calendar.current.dateComponents([.day, .hour, .minute], from: createdAt, to: Date())
        if let d = comps.day, d > 0 { return "\(d)d" }
        if let h = comps.hour, h > 0 { return "\(h)h" }
        return "\(comps.minute ?? 0)m"
    }
}

struct PRUser: Codable, Sendable {
    let login: String
}

struct PRBranch: Codable, Sendable {
    let ref: String
}
