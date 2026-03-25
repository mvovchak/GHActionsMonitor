import SwiftUI

struct RepoPickerView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var searchText = ""
    @State private var availableRepos: [GitHubRepo] = []
    @State private var isLoading = false

    private var filtered: [GitHubRepo] {
        guard !searchText.isEmpty else { return availableRepos }
        return availableRepos.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [(owner: String, repos: [GitHubRepo])] {
        Dictionary(grouping: filtered, by: \.owner)
            .sorted { $0.key.lowercased() < $1.key.lowercased() }
            .map { ($0.key, $0.value) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                TextField("Search repositories…", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isLoading {
                    ProgressView().scaleEffect(0.6)
                } else if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))

            // Repo list
            if availableRepos.isEmpty && isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading repositories…").font(.callout)
                    Spacer()
                }
                .padding(.vertical, 16)
            } else if grouped.isEmpty {
                Text(searchText.isEmpty ? "No repositories found." : "No results for \"\(searchText)\"")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(grouped, id: \.owner) { owner, repos in
                            Text(owner.uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.top, 8)
                                .padding(.bottom, 2)
                            ForEach(repos) { repo in
                                let isAdded = settings.repositories.contains {
                                    $0.fullName == repo.fullName
                                }
                                RepoPickerRow(repo: repo, isAdded: isAdded) {
                                    toggleRepo(repo)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(height: 200)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2)))
            }
        }
        .task { await loadRepos() }
        .onChange(of: settings.personalAccessToken) { _, _ in
            Task { await loadRepos() }
        }
    }

    private func toggleRepo(_ repo: GitHubRepo) {
        if let idx = settings.repositories.firstIndex(where: { $0.fullName == repo.fullName }) {
            settings.repositories.remove(at: idx)
        } else {
            settings.repositories.append(Repository(fullName: repo.fullName))
        }
    }

    private func loadRepos() async {
        let token = settings.personalAccessToken
        guard !token.isEmpty else { return }
        isLoading = true
        availableRepos = (try? await GitHubAPIClient().fetchUserRepos(token: token)) ?? []
        isLoading = false
    }
}

struct RepoPickerRow: View {
    let repo: GitHubRepo
    let isAdded: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isAdded ? .blue : Color.secondary.opacity(0.4))
                    .imageScale(.small)
                    .frame(width: 16)
                Text(repo.repoName)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if repo.isPrivate {
                    Image(systemName: "lock")
                        .imageScale(.small)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isAdded ? Color.blue.opacity(0.07) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
