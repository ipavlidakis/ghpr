import ArgumentParser
import AuthenticationModule
import Foundation

struct AuthCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Manage the GitHub token ghpr uses.",
        subcommands: [Token.self, Status.self, Logout.self]
    )
}

extension AuthCommand {
    struct Token: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "token",
            abstract: "Store a GitHub personal access token in the macOS Keychain.",
            discussion: """
                Create the token at https://github.com/settings/tokens — either a \
                fine-grained token with pull-requests read/write and contents read, \
                or a classic token with the `repo` scope.
                """
        )

        func run() async throws {
            let token = try readToken()
            try await KeychainTokenStore().write(token)
            print("Token \(masked(token)) saved to the macOS Keychain.")
        }

        private func readToken() throws -> String {
            let input: String?
            if isatty(STDIN_FILENO) == 1 {
                input = readLineWithHiddenInput(prompt: "Paste your GitHub personal access token (input is hidden): ")
            } else {
                input = readLine()
            }

            guard let token = input?.trimmingCharacters(in: .whitespacesAndNewlines), !token.isEmpty else {
                throw ValidationError("No token provided.")
            }
            return token
        }

        private func readLineWithHiddenInput(prompt: String) -> String? {
            var terminal = termios()
            tcgetattr(STDIN_FILENO, &terminal)
            var withoutEcho = terminal
            withoutEcho.c_lflag &= ~tcflag_t(ECHO)
            tcsetattr(STDIN_FILENO, TCSANOW, &withoutEcho)
            defer { tcsetattr(STDIN_FILENO, TCSANOW, &terminal) }

            print(prompt, terminator: "")
            let line = readLine()
            print()
            return line
        }
    }

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
            print("Authenticated via \(token.source): \(masked(token.value))")
        }
    }

    struct Logout: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "logout",
            abstract: "Remove the stored token from the macOS Keychain."
        )

        func run() async throws {
            if try await KeychainTokenStore().delete() {
                print("Removed the GitHub token from the macOS Keychain.")
            } else {
                print("No GitHub token was stored in the macOS Keychain.")
            }
        }
    }
}

private func masked(_ token: String) -> String {
    guard token.count > 8 else { return String(repeating: "•", count: token.count) }
    return "\(token.prefix(4))…\(token.suffix(4))"
}
