import ArgumentParser
import AuthenticationModule
import Foundation
import GithubModule

/// Hidden command rendering a real, large public pull request summary in the
/// terminal. The data is loaded read-only.
struct DemoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demo",
        abstract: "Print a large public pull request summary in the terminal.",
        shouldDisplay: false
    )

    func run() throws {
        let reference = GithubPullRequestReference(
            repository: GithubRepository(owner: "oven-sh", name: "bun"),
            number: 30412
        )
        let data = try AsyncBridge.run {
            let token = await TokenResolver().resolve()?.value
            let client = GithubClient(token: token)
            print("Loading \(reference.repository.fullName) #\(reference.number)…")
            return try await ReviewData.load(with: client, reference: reference)
        }

        print("Demo pull request summary:")
        data.printSummary()
    }
}
