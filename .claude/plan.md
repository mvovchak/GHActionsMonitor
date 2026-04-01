# GHActionsMonitor — Open Source / GitHub Releases Readiness Plan

Goal: ship a clean, installable open-source release via GitHub Releases + Sparkle.
No App Store. Direct distribution only.

---

## Tasks

### 1. Bug: Failure notifications re-fire after every settings change [x]
`PollingService.restartPolling()` resets `seenFailureIds = []`, so changing any
setting (token, repo list, poll interval) re-sends notifications for every known
failure. Fix: only clear seen IDs when the token or repo list actually changes,
not on every restart.
File: PollingService.swift:50-65

### 2. UX: First-launch onboarding — no raw error on empty token [x]
When no token is configured, the popover shows a raw error string
"No GitHub token. Open Settings to add one." in the footer.
Replace with a centred empty-state in the popover body: brief message + a button
that opens Settings directly.
Files: ActionsView.swift, PRsView.swift, PopoverView.swift

### 3. UX: Token validation feedback in Settings [x]
After the user types a token there is no feedback on whether it is valid.
Add an async "Verify" button that calls fetchCurrentUserLogin and shows
✓ username or an inline error.
File: SettingsView.swift

### 4. UX: Notification permission denied — surface in Settings [x]
If the user has denied notification permission, the app silently skips all
notifications with no indication. Add a yellow warning banner in Settings
when UNAuthorizationStatus is .denied, with a button to open System Settings.
File: SettingsView.swift

### 5. UX: Empty states in Actions / PRs views [x]
When there are no active runs or no failures, the sections disappear with no
message. Add explicit "No active runs" / "No recent failures" / "No open PRs"
placeholder rows so the UI does not look broken.
Files: ActionsView.swift, PRsView.swift

### 6. UX: Restore cmd+, keyboard shortcut for Settings [x]
Replacing SettingsLink with a custom Button broke the standard macOS cmd+,
shortcut. Fix by adding a hidden MenuBarExtra command or a .commands modifier
that routes cmd+, to the same action.
File: GHActionsMonitorApp.swift

### 7. Robustness: Cap fetchRecentFailures pagination [x]
fetchRecentFailures fetches ALL pages of failures on every poll. A repo with
hundreds of old failures wastes quota. Cap at 1 page (100 runs) — we only need
recent ones for notification deduplication.
File: GitHubAPIClient.swift

### 8. Robustness: Proactive rate-limit display [x]
Parse the X-RateLimit-Remaining response header and surface a warning in the
popover footer when remaining < 100 (instead of only reacting to a 429).
Files: GitHubAPIClient.swift, PollingService.swift, PopoverView.swift

### 9. Release: Ensure appcast.xml + GitHub Actions release workflow exist [x] — already existed, verified complete
Verify or create:
- appcast.xml at repo root (Sparkle feed)
- .github/workflows/release.yml that builds, signs, notarizes, and uploads
  the .dmg and updates appcast.xml on every version tag push.

### 10. Repo: README with install instructions [x] — already existed, verified complete
Write a clear README.md:
- What it does + screenshot
- Requirements (macOS 14+, GitHub PAT with repo+workflow scopes)
- Install options: download .dmg from Releases, or `brew install` (if tap exists)
- How to build from source
- License

---

## Order of execution
1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10
