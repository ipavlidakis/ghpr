// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ghpr",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "ghpr", targets: ["ghpr"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "ghpr",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "AuthenticationModule",
                "GithubModule",
                "UIModule",
            ],
            resources: [.copy("Resources/demo.diff")]
        ),
        .target(name: "AuthenticationModule", path: "Sources/Modules/AuthenticationModule"),
        .target(name: "GithubModule", path: "Sources/Modules/GithubModule"),
        .target(
            name: "UIModule",
            dependencies: ["GithubModule"],
            path: "Sources/Modules/UIModule"
        ),
        .testTarget(
            name: "AuthenticationModuleTests",
            dependencies: ["AuthenticationModule"],
            path: "Tests/Modules/AuthenticationModuleTests"
        ),
        .testTarget(
            name: "GithubModuleTests",
            dependencies: ["GithubModule"],
            path: "Tests/Modules/GithubModuleTests",
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "ghprTests",
            dependencies: ["ghpr", "GithubModule"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
