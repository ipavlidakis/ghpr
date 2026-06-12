# ghpr

Review GitHub pull requests in a native macOS window, straight from your terminal.

Pure Swift/SwiftUI — no Electron, no webviews. One command opens a full review window: description, checks, commits, and a fast syntax-highlighted diff with inline comment threads, reactions, pending review batches, and approve / request-changes / comment.

## Install

```bash
brew install ipavlidakis/tap/ghpr
```

Or from source (requires a recent Xcode):

```bash
git clone https://github.com/ipavlidakis/ghpr.git
cd ghpr && make dist
# unpack dist/ghpr-*.tar.gz anywhere and keep the bundles next to the binary
```

## Authenticate

`ghpr` resolves a GitHub token from, in order: the `GHPR_TOKEN` or `GITHUB_TOKEN` environment variables, the macOS Keychain, or a signed-in `gh` CLI (borrowed silently).

```bash
ghpr auth token     # paste a PAT once, stored in the Keychain
ghpr auth status    # which token would be used, and where it comes from
ghpr auth logout    # remove the stored token
```

Fine-grained tokens need pull-requests read/write and contents read; classic tokens need the `repo` scope.

## Use

```bash
ghpr                                          # open the PR for the current branch,
                                              # or the dashboard if there is none
ghpr https://github.com/owner/repo/pull/123   # open a specific PR
ghpr dash                                     # browse the repo's open PRs
```

Inside the review window:

- **Conversation / Commits / Checks / Files changed** tabs, GitHub-style.
- Continuous scroll through all files; the sidebar follows your position.
- Hover a line and click **+** to comment — batch into a review or post immediately.
- Reply, resolve, and react to existing threads inline.
- **Viewed** checkboxes per file (persisted across sessions until the file changes).
- Drag across lines to select; cmd-C or right-click to copy.
- **Submit review** (top right): comment, approve, or request changes.

## Requirements

- macOS 14+ (Apple Silicon binary; build from source for Intel).
- A GitHub token (see above). GitHub Enterprise is not supported yet.

## Development

```bash
swift build && swift test
```

The architecture and milestone history live in [PLAN.md](PLAN.md).
