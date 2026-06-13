# ghpr — Agent instructions

## Core principles

- **Simplicity above all.** Code must always be as simple as possible, clean, and readable. If something can be expressed with less code or fewer concepts, do that. No speculative abstractions.
- **Clear, one-directional data flow.** Data flows one way (CLI entry → modules → state → views). No back-channels, no shared mutable singletons, no two-way coupling between layers.
- **Swift concurrency only.** Use async/await and structured concurrency everywhere. Never introduce GCD, locks, semaphores, or completion-handler APIs.
- **Prefer actors.** Shared mutable state and external resources (Keychain, subprocesses, caches) always live behind actors — never any other synchronization mechanism.
- **One file per type definition** Each class|struct|enum|protocol|extension gets its own file
- **Name files format** should be simple, short and clear. If the content of file is an extension the format should be <ExtendedContent>+<Extension description>
- **Docc comments** should be added everywhere whenever it makes sense. Avoid adding unnecessary comments that don't add any value. Keep the comments focused, clean, short and simple.
**Models** should be simple, lightweight structs with no complex logic or dependencies and only being created if there is nothing else already covering the same concept.
## Conventions

- Naming: prefer `Github` over a `GH` prefix (`GithubClient`, not `GHClient`).
- Every Swift source file declares its imports explicitly: `import Foundation` is the minimum and must always be present.
- Cross-module API uses the `package` access level, never `public` — everything ships in one package with one product.
- Tests use Swift Testing (`import Testing`), never XCTest.
- Prefer `List` over `LazyVStack` in a `ScrollView` for long scrollable content: `List` recycles rows (NSTableView-backed on macOS), lazy stacks do not and drop frames.
- For high-volume UI containers (diffs, timelines, large comment feeds, large file lists), prefer AppKit-backed virtualization (`NSTableView`/`NSOutlineView`) and host SwiftUI only inside rows/cards. SwiftUI `ScrollView`, `LazyVStack`, and `Grid` are acceptable for small bounded content, not unbounded PR-scale containers.
- Prefer intrinsic and self-sizing layout over hardcoded dimensions. Use fixed sizes only when they are required for correctness, platform behavior, or measurable performance.
- Every milestone must build (`swift build`) and pass its tests (`swift test`) before it is committed.
- All UI related code lives in the `UIModule` target.

## Liquid Glass and macOS UI

Essence from https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo:

- Prefer system-provided Liquid Glass first. Native toolbars, sidebars, sheets, popovers, menus, window controls, and standard controls should get the system treatment automatically when built with current SDKs.
- Keep glass in the navigation/control layer only. Use it for title bars, toolbars, sidebars, floating controls, sheets, popovers, and menus; do not apply glass to content lists, cards, tables, scroll views, or full-screen backgrounds.
- Never stack glass on glass. One glass layer over content. If multiple custom glass elements sit together, group them in one `GlassEffectContainer`/`NSGlassEffectContainerView`.
- Prefer regular glass by default. Use clear glass only over rich media or bold visual content where the dimming behavior will not harm legibility. Do not mix regular and clear glass in the same control group.
- Tint sparingly. Only primary actions should be tinted or prominent; decorative tinting across multiple glass controls makes hierarchy unclear.
- For SwiftUI custom controls, prefer `.glassEffect()`, `.buttonStyle(.glass)`, and `.buttonStyle(.glassProminent)` before custom backgrounds.
- For AppKit custom controls, prefer native glass APIs such as `NSGlassEffectView`, `NSGlassEffectContainerView`, toolbar item styles, and system bezel styles. Avoid hand-rolled blur, opacity, or material clones.
- Let content extend behind transparent title bars and toolbars when glass should sample content. Use `backgroundExtensionEffect()` or safe-area-aware layout instead of painting opaque toolbar backgrounds.
- Respect accessibility. System glass adapts to Reduce Transparency, Increase Contrast, and Reduce Motion; avoid custom effects that bypass those adaptations.
