import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var newRepoInput = ""
    @State private var showInvalidRepoAlert = false
    @State private var duplicateRepo = ""

    var body: some View {
        Form {
            Section {
                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $settings.personalAccessToken)
                    .textFieldStyle(.roundedBorder)
                Text("Requires **repo** and **workflow** scopes. Stored in UserDefaults (not Keychain).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("GitHub Token")
            }

            Section {
                if settings.repositories.isEmpty {
                    Text("No repositories added yet.")
                        .foregroundStyle(.tertiary)
                        .font(.callout)
                        .padding(.vertical, 4)
                } else {
                    ForEach(settings.repositories) { repo in
                        RepoRowView(repo: repo) {
                            settings.repositories.removeAll { $0.id == repo.id }
                        }
                    }
                }

                HStack {
                    TextField("owner/repo", text: $newRepoInput)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addRepo() }
                    Button("Add") { addRepo() }
                        .disabled(newRepoInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.top, 2)

            } header: {
                Text("Watched Repositories")
            } footer: {
                Text("Polling every 60 seconds  ·  \(settings.repositories.count) repo(s) watched")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 420)
        .alert("Invalid Repository", isPresented: $showInvalidRepoAlert) {
            Button("OK") {}
        } message: {
            Text("Use the format \"owner/repo\", e.g. \"apple/swift\".")
        }
    }

    private func addRepo() {
        let repo = Repository(fullName: newRepoInput)
        guard repo.isValid else {
            showInvalidRepoAlert = true
            return
        }
        guard !settings.repositories.contains(where: { $0.fullName == repo.fullName }) else {
            newRepoInput = ""
            return
        }
        settings.repositories.append(repo)
        newRepoInput = ""
    }
}
