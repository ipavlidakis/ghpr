extension String {
    /// Masks a secret for display, keeping only the first and last four characters.
    var masked: String {
        guard count > 8 else { return String(repeating: "•", count: count) }
        return "\(prefix(4))…\(suffix(4))"
    }
}
