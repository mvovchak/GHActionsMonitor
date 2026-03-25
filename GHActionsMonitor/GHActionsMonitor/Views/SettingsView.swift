import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    private let pollOptions: [(label: String, seconds: Int)] = [
        ("30 seconds", 30),
        ("1 minute",   60),
        ("5 minutes",  300)
    ]

    var body: some View {
        Form {
            Section {
                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $settings.personalAccessToken)
                    .textFieldStyle(.roundedBorder)
                Text("Requires **repo** and **workflow** scopes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("GitHub Token")
            }

            Section {
                if !settings.repositories.isEmpty {
                    ForEach(settings.repositories) { repo in
                        RepoRowView(repo: repo) {
                            settings.repositories.removeAll { $0.id == repo.id }
                        }
                    }
                }

                RepoPickerView()
                    .environmentObject(settings)
                    .padding(.vertical, 4)

            } header: {
                Text("Watched Repositories")
            } footer: {
                Text("\(settings.repositories.count) repo(s) watched")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch at Login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
                Toggle("Hide Draft Pull Requests", isOn: $settings.hideDraftPRs)

                Picker("Poll Interval", selection: $settings.pollIntervalSeconds) {
                    ForEach(pollOptions, id: \.seconds) { option in
                        Text(option.label).tag(option.seconds)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 260)
            } header: {
                Text("Preferences")
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 480, height: 620)
    }
}
