import SwiftUI

struct PRsView: View {
    @EnvironmentObject var pollingService: PollingService
    @ObservedObject private var settings = AppSettings.shared

    private var visiblePRs: [PullRequest] {
        settings.hideDraftPRs ? pollingService.openPRs.filter { !$0.draft } : pollingService.openPRs
    }

    private var needsReview: [PullRequest] {
        visiblePRs.filter { pr in
            pr.requestedReviewers.map(\.login).contains(pollingService.currentUserLogin)
        }
    }

    private var yourPRs: [PullRequest] {
        visiblePRs.filter { $0.user.login == pollingService.currentUserLogin }
    }

    private var otherPRs: [PullRequest] {
        let login = pollingService.currentUserLogin
        return visiblePRs.filter { pr in
            pr.user.login != login &&
            !pr.requestedReviewers.map(\.login).contains(login)
        }
    }

    var body: some View {
        if visiblePRs.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !needsReview.isEmpty {
                        PRSectionHeader(title: "NEEDS YOUR REVIEW", count: needsReview.count, color: .orange)
                        ForEach(needsReview) { pr in
                            PRRowView(pr: pr, kind: .needsReview,
                                      reviewDecision: pollingService.prReviewDecisions[pr.id] ?? .none)
                            Divider().padding(.leading, 34)
                        }
                    }

                    if !yourPRs.isEmpty {
                        PRSectionHeader(title: "YOUR PULL REQUESTS", count: yourPRs.count, color: .blue)
                        ForEach(yourPRs) { pr in
                            PRRowView(pr: pr, kind: .yours,
                                      reviewDecision: pollingService.prReviewDecisions[pr.id] ?? .none)
                            Divider().padding(.leading, 34)
                        }
                    }

                    if !otherPRs.isEmpty {
                        PRSectionHeader(title: "OPEN IN WATCHED REPOS", count: otherPRs.count, color: .secondary)
                        ForEach(otherPRs) { pr in
                            PRRowView(pr: pr, kind: .other,
                                      reviewDecision: pollingService.prReviewDecisions[pr.id] ?? .none)
                            Divider().padding(.leading, 34)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            if settings.repositories.isEmpty {
                Image(systemName: "tray")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No repositories watched")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Add in Settings") { openSettings() }
                    .font(.callout)
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("No open pull requests")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        DispatchQueue.main.async {
            NSApp.windows.first { $0.title == "Settings" }?.makeKeyAndOrderFront(nil)
        }
    }
}

struct PRSectionHeader: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(color.opacity(0.7), in: Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }
}
