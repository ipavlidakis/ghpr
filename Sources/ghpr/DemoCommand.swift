import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// Hidden command rendering a real, large public pull request in a review
/// window. Write interactions are local-only so the demo cannot mutate GitHub.
struct DemoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demo",
        abstract: "Render a large public pull request in a native window.",
        shouldDisplay: false
    )

    func run() throws {
        let reference = GithubPullRequestReference(
            repository: GithubRepository(owner: "oven-sh", name: "bun"),
            number: 30412
        )
        let destination = try AsyncBridge.run {
            let token = await TokenResolver().resolve()?.value
            let client = GithubClient(token: token)
            print("Loading \(reference.repository.fullName) #\(reference.number)…")
            return (try await ReviewData.load(with: client, reference: reference), client)
        }
        let (data, client) = destination

        // A synchronous ParsableCommand runs on the main thread.
        MainActor.assumeIsolated {
            AppBootstrap.run(
                title: "\(data.reference.repository.fullName) #\(data.reference.number) — \(data.pullRequest.title)",
                content: ReviewScreen(model: ReviewModel(
                    data: data,
                    client: client,
                    writesAreMocked: true
                ))
            )
        }
    }
}
