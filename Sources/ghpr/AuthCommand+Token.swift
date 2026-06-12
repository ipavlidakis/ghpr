import ArgumentParser
import AuthenticationModule
import Foundation

extension AuthCommand {
    /// Reads a personal access token (hidden prompt or stdin) and stores it in the Keychain.
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
            print("Token \(token.masked) saved to the macOS Keychain.")
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

        /// Reads one line from the terminal with echo disabled, restoring the terminal state afterwards.
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
}
