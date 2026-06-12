// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ghpr",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ghpr", targets: ["ghpr"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", from: "0.25.0"),
        .package(url: "https://github.com/alex-pinkus/tree-sitter-swift", branch: "with-generated-files"),
        // Newer tags of these grammars ship manifests whose relative-path
        // fileExists check silently drops scanner.c, breaking the link.
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-objc", .upToNextMinor(from: "2.1.0")),
        .package(url: "https://github.com/tree-sitter/tree-sitter-c", from: "0.24.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-cpp", from: "0.23.4"),
        .package(url: "https://github.com/fwcd/tree-sitter-kotlin", from: "0.3.8"),
        // 0.25.0's manifest drops scanner.c (relative-path fileExists check), breaking the link.
        .package(url: "https://github.com/tree-sitter/tree-sitter-javascript", .upToNextMinor(from: "0.23.1")),
        .package(url: "https://github.com/tree-sitter/tree-sitter-typescript", from: "0.23.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-json", from: "0.24.8"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-yaml", exact: "0.7.0"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown", from: "0.5.3"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-python", .upToNextMinor(from: "0.23.6")),
        .package(url: "https://github.com/tree-sitter/tree-sitter-bash", from: "0.25.1"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-rust", from: "0.24.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-go", from: "0.25.0")
    ],
    targets: [
        .executableTarget(
            name: "ghpr",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "AuthenticationModule",
                "DiffUIModule",
                "GithubModule"
            ],
            resources: [.copy("Resources/demo.diff")]
        ),
        .target(name: "AuthenticationModule"),
        .target(name: "GithubModule"),
        .target(
            name: "DiffUIModule",
            dependencies: [
                .product(name: "SwiftTreeSitter", package: "swift-tree-sitter"),
                .product(name: "TreeSitterSwift", package: "tree-sitter-swift"),
                .product(name: "TreeSitterObjc", package: "tree-sitter-objc"),
                .product(name: "TreeSitterC", package: "tree-sitter-c"),
                .product(name: "TreeSitterCPP", package: "tree-sitter-cpp"),
                .product(name: "TreeSitterKotlin", package: "tree-sitter-kotlin"),
                .product(name: "TreeSitterJavaScript", package: "tree-sitter-javascript"),
                .product(name: "TreeSitterTypeScript", package: "tree-sitter-typescript"),
                .product(name: "TreeSitterJSON", package: "tree-sitter-json"),
                .product(name: "TreeSitterYAML", package: "tree-sitter-yaml"),
                .product(name: "TreeSitterMarkdown", package: "tree-sitter-markdown"),
                .product(name: "TreeSitterPython", package: "tree-sitter-python"),
                .product(name: "TreeSitterBash", package: "tree-sitter-bash"),
                .product(name: "TreeSitterRust", package: "tree-sitter-rust"),
                .product(name: "TreeSitterGo", package: "tree-sitter-go")
            ]
        ),
        .testTarget(
            name: "DiffUIModuleTests",
            dependencies: ["DiffUIModule"],
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "AuthenticationModuleTests",
            dependencies: ["AuthenticationModule"]
        ),
        .testTarget(
            name: "GithubModuleTests",
            dependencies: ["GithubModule"],
            resources: [.copy("Fixtures")]
        )
    ]
)
