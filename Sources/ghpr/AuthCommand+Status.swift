import ArgumentParser
import AuthenticationModule
import Foundation

/// The `ghpr auth status` subcommand.
extension AuthCommand {
    /// Reports which token ghpr would use and from which source, or how to authenticate.
    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "status",
            abstract: "Show which token ghpr would use, and where it comes from."
        )

        func run() async throws {
            guard let token = await TokenResolver().resolve() else {
                print("""
                No GitHub token found. To authenticate, either:
                  • run `ghpr auth token` to store a personal access token in the Keychain,
                  • export GHPR_TOKEN or GITHUB_TOKEN, or
                  • sign in to the gh CLI (`gh auth login`) and ghpr will borrow its token.
                """)
                throw ExitCode.failure
            }
            print("Authenticated via \(token.source): \(token.value.masked)")
        }
    }
}
