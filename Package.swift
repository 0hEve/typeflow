// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TypeFlow",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "TypeFlow", targets: ["TypeFlow"])
    ],
    targets: [
        .executableTarget(
            name: "TypeFlow",
            path: "Sources/TypeFlow"
        )
    ]
)
