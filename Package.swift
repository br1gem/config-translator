// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ConfigTranslator",
    products: [
        .executable(name: "config-translator", targets: ["ConfigTranslator"])
    ],
    targets: [
        .executableTarget(name: "ConfigTranslator", path: "src")
    ]
)
