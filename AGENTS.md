# ghpr — Agent instructions

Read `PLAN.md` first: it is the source of truth for scope, architecture decisions, and milestones.

## Core principles

- **Simplicity above all.** Code must always be as simple as possible, clean, and readable. If something can be expressed with less code or fewer concepts, do that. No speculative abstractions.
- **Clear, one-directional data flow.** Data flows one way (CLI entry → modules → state → views). No back-channels, no shared mutable singletons, no two-way coupling between layers.
- **Swift concurrency only.** Use async/await and structured concurrency everywhere. Never introduce GCD, locks, semaphores, or completion-handler APIs.
- **Prefer actors.** Shared mutable state and external resources (Keychain, subprocesses, caches) always live behind actors — never any other synchronization mechanism.

## Conventions

- Naming: prefer `Github` over a `GH` prefix (`GithubClient`, not `GHClient`).
- Tests use Swift Testing (`import Testing`), never XCTest.
- Every milestone must build (`swift build`) and pass its tests (`swift test`) before it is committed.
