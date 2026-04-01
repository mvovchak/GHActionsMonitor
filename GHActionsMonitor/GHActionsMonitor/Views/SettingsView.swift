import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    private let pollOptions: [(label: String, seconds: Int)] = [
        ("30 seconds", 30),
        ("1 minute",   60),
        ("5 minutes",  300)
    ]

    private enum TokenValidation { case idle, loading, valid(String), invalid(String) }
    @State private var tokenValidation: TokenValidation = .idle
    @State private var notificationsAllowed: Bool = true

    var body: some View {
        Form {
            if !notificationsAllowed {
                notificationWarning
            }

            Section {
                SecureField("ghp_xxxxxxxxxxxxxxxxxxxx", text: $settings.personalAccessToken)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: settings.personalAccessToken) { tokenValidation = .idle }

                HStack(spacing: 8) {
                    Text("Requires **repo** and **workflow** scopes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    tokenValidationView
                    if !settings.personalAccessToken.isEmpty {
                        Button("Verify") { verifyToken() }
                            .font(.caption)
                            .disabled(isVerifying)
                    }
                }
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
        .task { await checkNotificationPermission() }
    }

    // MARK: - Token Validation

    private var isVerifying: Bool {
        if case .loading = tokenValidation { return true }
        return false
    }

    @ViewBuilder
    private var tokenValidationView: some View {
        switch tokenValidation {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView().controlSize(.small)
        case .valid(let username):
            Label(username, systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .invalid(let message):
            Label(message, systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func verifyToken() {
        let token = settings.personalAccessToken
        guard !token.isEmpty else { return }
        tokenValidation = .loading
        Task {
            do {
                let login = try await GitHubAPIClient().fetchCurrentUserLogin(token: token)
                tokenValidation = .valid(login)
            } catch {
                tokenValidation = .invalid("Invalid token")
            }
        }
    }

    // MARK: - Notification Permission

    private var notificationWarning: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Notifications are disabled")
                        .font(.callout.weight(.medium))
                    Text("Enable them in System Settings to receive alerts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Open") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
                }
                .font(.caption)
            }
        }
    }

    private func checkNotificationPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsAllowed = settings.authorizationStatus != .denied
    }
}
