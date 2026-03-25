import Foundation
import Combine
import ServiceManagement

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var personalAccessToken: String {
        didSet { KeychainService.save(personalAccessToken) }
    }

    @Published var repositories: [Repository] {
        didSet {
            if let data = try? JSONEncoder().encode(repositories) {
                UserDefaults.standard.set(data, forKey: "repos")
            }
        }
    }

    @Published var hideDraftPRs: Bool {
        didSet { UserDefaults.standard.set(hideDraftPRs, forKey: "hideDrafts") }
    }

    @Published var pollIntervalSeconds: Int {
        didSet { UserDefaults.standard.set(pollIntervalSeconds, forKey: "pollInterval") }
    }

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch {
                print("LaunchAtLogin error: \(error)")
            }
        }
    }

    private init() {
        // Migrate PAT from UserDefaults to Keychain (one-time, for existing users)
        if KeychainService.load() == nil,
           let legacy = UserDefaults.standard.string(forKey: "pat"), !legacy.isEmpty {
            KeychainService.save(legacy)
            UserDefaults.standard.removeObject(forKey: "pat")
        }

        let saved = KeychainService.load() ?? ""
        if saved.isEmpty, let ghToken = Self.loadGHCliToken() {
            self.personalAccessToken = ghToken
            KeychainService.save(ghToken)
        } else {
            self.personalAccessToken = saved
        }

        if let data = UserDefaults.standard.data(forKey: "repos"),
           let repos = try? JSONDecoder().decode([Repository].self, from: data) {
            self.repositories = repos
        } else {
            self.repositories = []
        }

        self.hideDraftPRs = UserDefaults.standard.bool(forKey: "hideDrafts")
        let savedInterval = UserDefaults.standard.integer(forKey: "pollInterval")
        self.pollIntervalSeconds = savedInterval > 0 ? savedInterval : 60
    }

    private static func loadGHCliToken() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["gh", "auth", "token"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        try? process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let token = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return token.flatMap { $0.isEmpty ? nil : $0 }
    }
}
