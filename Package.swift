// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ghpr",
    platforms: [.macOS(.v14)],
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
                "AuthenticationModule"
            ]
        ),
        .target(name: "AuthenticationModule"),
        .target(name: "GithubModule"),
        .target(name: "DiffUIModule"),
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
