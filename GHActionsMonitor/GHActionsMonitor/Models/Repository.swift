import Foundation

// Lightweight model returned by the GitHub /user/repos API
struct GitHubRepo: Codable, Identifiable, Sendable {
    let id: Int
    let fullName: String
    let isPrivate: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case isPrivate = "private"
    }

    var owner: String   { String(fullName.split(separator: "/").first ?? "") }
    var repoName: String { String(fullName.split(separator: "/").last ?? "") }
}

struct Repository: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var fullName: String

    init(fullName: String) {
        self.id = UUID()
        self.fullName = fullName.trimmingCharacters(in: .whitespaces)
    }

    var owner: String { String(fullName.split(separator: "/").first ?? "") }
    var repoName: String { String(fullName.split(separator: "/").last ?? "") }

    var isValid: Bool {
        let parts = fullName.split(separator: "/")
        return parts.count == 2 && parts[0].count > 0 && parts[1].count > 0
    }
}
