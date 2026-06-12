# ghpr

Review GitHub pull requests in a fully native macOS window, straight from your terminal. No Electron, no webviews — Swift, SwiftUI, and AppKit all the way down.

```bash
ghpr                                          # review the open PR for the current branch
ghpr https://github.com/owner/repo/pull/123   # review a specific PR
ghpr dash                                     # browse the repo's open PRs
```

## Features

- **Native review window** — PR description (rendered markdown), commits, CI checks, and a continuous, GitHub-style scroll through every changed file with syntax highlighting (tree-sitter), intra-line word diffs, and a file tree sidebar that follows your scroll position.
- **Full review write path** — inline comments (hover a line for the `+` button), pending review batches, approve / request changes / comment, replies, emoji reactions, and thread resolution.
- **Viewed tracking** — per-file Viewed checkboxes with progress, persisted across sessions and invalidated automatically when a file's diff changes.
- **Dashboard** — open PRs with All / Mine / Review-requested filters; selecting one opens a review window in the same process.
- **Fast on purpose** — fixed-row-height `NSTableView` rendering; a 20k-line patch opens instantly.
- **Zero git writes** — only read-only queries (`origin` URL, current branch); reviewing is fully remote via the GitHub API.

## Install

### Homebrew

```bash
brew install ipavlidakis/tap/ghpr
```

Apple Silicon, macOS 14+.

### From source

```bash
git clone https://github.com/ipavlidakis/ghpr.git
cd ghpr
make dist   # builds dist/ghpr-v<version>-arm64-macos.tar.gz
```

The binary is not standalone — the `*.bundle` directories in the tarball must stay next to the executable.

## Authentication

ghpr resolves a token from, in priority order:

1. `GHPR_TOKEN` or `GITHUB_TOKEN` environment variables
2. the macOS Keychain — store one with `ghpr auth token` (fine-grained PAT with pull-requests read/write and contents read, or a classic token with `repo` scope)
3. an authenticated [`gh`](https://cli.github.com) CLI, borrowed silently

```bash
ghpr auth token    # store a PAT in the Keychain
ghpr auth status   # which token would be used, and where it comes from
ghpr auth logout   # remove the stored token
```

## Usage

| Command | Effect |
| --- | --- |
| `ghpr` | Open the PR for the current repo + branch, or the dashboard if there is none |
| `ghpr <pr-url>` | Open that PR |
| `ghpr dash` | Open the dashboard of open PRs |
| `ghpr --detach` / `ghpr dash --detach` | Same, but hand the terminal back immediately |

In the review window: click a line's `+` to comment (batch into a review or send immediately), drag across lines to select and copy code, `j`/`k` to jump between files, ⌘↩ to submit your review. Closing the last window exits the process and returns your terminal.

## Development

```bash
swift build && swift test
```

The package is a single product with four targets: `ghpr` (composition root + UI screens), `GithubModule` (REST/GraphQL client), `DiffUIModule` (diff parsing and rendering, GitHub-unaware), and `AuthenticationModule` (token chain). See `PLAN.md` for architecture decisions.

## License

MIT — see [LICENSE](LICENSE).
