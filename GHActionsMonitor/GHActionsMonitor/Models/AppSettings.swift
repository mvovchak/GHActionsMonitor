import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var personalAccessToken: String {
        didSet { UserDefaults.standard.set(personalAccessToken, forKey: "pat") }
    }

    @Published var repositories: [Repository] {
        didSet {
            if let data = try? JSONEncoder().encode(repositories) {
                UserDefaults.standard.set(data, forKey: "repos")
            }
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "pat") ?? ""
        if saved.isEmpty, let ghToken = Self.loadGHCliToken() {
            self.personalAccessToken = ghToken
            UserDefaults.standard.set(ghToken, forKey: "pat")
        } else {
            self.personalAccessToken = saved
        }

        if let data = UserDefaults.standard.data(forKey: "repos"),
           let repos = try? JSONDecoder().decode([Repository].self, from: data) {
            self.repositories = repos
        } else {
            self.repositories = []
        }
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
