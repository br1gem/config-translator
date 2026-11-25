// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "config-translator",
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-parsing.git",
            exact: "0.15.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "config-translator",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing")
            ],
            path: "src"
        )
    ]
)