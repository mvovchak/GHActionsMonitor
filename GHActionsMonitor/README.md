# GHActionsMonitor

A native macOS menu bar app that monitors GitHub Actions CI runs and pull requests across multiple repositories — no browser tab required.

**Requires macOS 14 (Sonoma) or later.**

---

## Setup checklist (before publishing)

These steps are one-time and must be done before the repo is open and usable by others:

- [ ] **Push the repo** — `git init`, `git remote add origin git@github.com:mvovchak/GHActionsMonitor.git`, push
- [ ] **Add `.gitignore`** — exclude `build/`, `*.xcarchive`, `*.dmg`, `DerivedData/` (see below)
- [ ] **Add Apple Developer secrets** to the GitHub repo for signed + notarized CI releases (see [Releasing](#releasing-ci))
- [ ] **Ship v1.0.0** — push `git tag v1.0.0 && git push origin v1.0.0`, wait for CI, download the DMG, sign it with `sign_update`, update `appcast.xml`, push

Until the Apple Developer secrets are added, CI will produce an **unsigned DMG** — users will need to right-click → Open on first launch. Notarized releases remove that friction.

### Recommended `.gitignore`

```
build/
*.xcarchive
*.dmg
DerivedData/
*.xcuserstate
xcuserdata/
.DS_Store
```

---

## Features

- **Actions tab** — live running workflow count in the menu bar icon; running and recent failure sections
- **Pull Requests tab** — PRs grouped by: Needs Your Review / Your PRs / Open in Watched Repos
- **Review status badges** — approved ✓ / changes requested ✗ per PR
- **Stale PR highlight** — flags PRs with no activity for 3+ days
- **Notifications** — workflow failures, review requests, PR approved, changes requested
- **Context menus** — open in browser, copy link, re-run failed workflows
- **Settings**
  - GitHub token (stored in Keychain)
  - Searchable repo picker grouped by org
  - Hide draft PRs toggle
  - Poll interval (30s / 1m / 5m)
  - Launch at login

---

## Installation

### Download (recommended)

1. Download the latest `.dmg` from [Releases](https://github.com/mvovchak/GHActionsMonitor/releases)
2. Open the DMG and drag **GHActionsMonitor** to `/Applications`
3. On first launch: right-click → **Open** to bypass Gatekeeper

> Releases are notarized when Apple Developer secrets are configured in CI (see [Releasing](#releasing-ci)). Until then, Gatekeeper bypass is manual.

### Build from source

**Requirements:** Xcode 15+, [xcodegen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
git clone https://github.com/mvovchak/GHActionsMonitor
cd GHActionsMonitor
xcodegen generate
open GHActionsMonitor.xcodeproj
```

Or build and install directly:
```bash
xcodebuild -scheme GHActionsMonitor -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/GHActionsMonitor.app /Applications/
xattr -dr com.apple.quarantine /Applications/GHActionsMonitor.app
```

---

## App setup

1. Open Settings (gear icon in the popover)
2. Paste a GitHub **Personal Access Token** with scopes:
   - `repo` — read pull requests and workflow runs
   - `workflow` — re-run workflows
3. Search and select the repositories to watch

If you have the [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login`), the token is loaded automatically on first launch.

---

## Releasing (CI)

Push a version tag to trigger the GitHub Actions release workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

CI builds a DMG and creates a GitHub Release. For signed + notarized releases, add these secrets to the repository (**Settings → Secrets and variables → Actions**):

| Secret | How to get it |
|--------|--------------|
| `APPLE_CERTIFICATE` | Export your **Developer ID Application** certificate from Keychain as a `.p12`, then: `base64 -i cert.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | The password you set when exporting the `.p12` |
| `APPLE_TEAM_ID` | 10-character ID on [developer.apple.com/account](https://developer.apple.com/account) → Membership |
| `APPLE_ID` | Your Apple ID email |
| `APPLE_APP_PASSWORD` | App-specific password from [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security |

A **Developer ID Application** certificate requires enrollment in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year). Without it, CI still builds and uploads an unsigned DMG.

---

## Publishing an update with auto-update (Sparkle)

After CI creates a new release and you have the signed DMG:

1. Get the EdDSA signature (private key is in your macOS Keychain from the one-time setup):
   ```bash
   /path/to/Sparkle/bin/sign_update GHActionsMonitor-X.Y.Z.dmg
   ```
   > Find `sign_update` in Xcode's derived data:
   > `find ~/Library/Developer/Xcode/DerivedData -name sign_update`

2. Edit `appcast.xml` — add a new `<item>` block (copy the existing one), update the version, release date, DMG URL, file size, and paste in the `sparkle:edSignature`.

3. Commit and push `appcast.xml` to `main`. Users on existing versions will be notified within their next poll cycle.

---

## Security

- The GitHub token is stored in the **macOS Keychain** (not UserDefaults or plaintext files)
- App Sandbox is **disabled** — required to read the token from the `gh` CLI via `Process()`. The app makes only outbound HTTPS requests to `api.github.com`
- No analytics, no telemetry, no third-party services
- The Sparkle EdDSA **private key lives only in your macOS Keychain** and never touches CI

---

## Contributing

Pull requests welcome. Please open an issue first for significant changes.

```bash
xcodegen generate   # required after adding or removing Swift source files
```

---

## License

MIT — see [LICENSE](LICENSE).
