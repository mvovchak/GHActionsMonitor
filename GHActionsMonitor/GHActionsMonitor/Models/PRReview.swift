import Foundation
import SwiftUI

struct PRReview: Codable, Sendable {
    let id: Int
    let user: PRUser
    let state: String       // APPROVED, CHANGES_REQUESTED, COMMENTED, DISMISSED, PENDING
    let submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, user, state
        case submittedAt = "submitted_at"
    }
}

enum ReviewDecision: String, Equatable {
    case approved           = "APPROVED"
    case changesRequested   = "CHANGES_REQUESTED"
    case none

    var label: String {
        switch self {
        case .approved:         return "Approved"
        case .changesRequested: return "Changes Requested"
        case .none:             return ""
        }
    }

    var color: some ShapeStyle {
        switch self {
        case .approved:         return AnyShapeStyle(.green)
        case .changesRequested: return AnyShapeStyle(.red)
        case .none:             return AnyShapeStyle(.secondary)
        }
    }

    var icon: String {
        switch self {
        case .approved:         return "checkmark.circle.fill"
        case .changesRequested: return "xmark.circle.fill"
        case .none:             return ""
        }
    }

    /// Compute aggregate decision from a reviews array, ignoring the PR author's own reviews.
    static func compute(from reviews: [PRReview], prAuthor: String) -> ReviewDecision {
        var latest: [String: String] = [:]
        for review in reviews.sorted(by: { ($0.submittedAt ?? .distantPast) < ($1.submittedAt ?? .distantPast) }) {
            guard review.user.login != prAuthor,
                  review.state != "COMMENTED",
                  review.state != "PENDING" else { continue }
            if review.state == "DISMISSED" {
                latest.removeValue(forKey: review.user.login)
            } else {
                latest[review.user.login] = review.state
            }
        }
        let decisions = Array(latest.values)
        if decisions.isEmpty { return .none }
        if decisions.contains("CHANGES_REQUESTED") { return .changesRequested }
        if decisions.allSatisfy({ $0 == "APPROVED" }) { return .approved }
        return .none
    }
}
