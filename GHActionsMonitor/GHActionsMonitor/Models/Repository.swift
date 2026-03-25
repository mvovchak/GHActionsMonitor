import Foundation

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
