// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "event-store-adapter-swift-support",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EventStoreAdapterSupport",
            targets: ["EventStoreAdapterSupport"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/lemo-nade-room/event-store-adapter-swift.git", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.6.0"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-distributed-actors.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "EventStoreAdapterSupport",
            dependencies: [
                .product(name: "EventStoreAdapter", package: "event-store-adapter-swift"),
                "EventStoreAdapterSupportMacro",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "EventStoreAdapterSupportTests",
            dependencies: [
                "EventStoreAdapterSupport",
                .product(name: "DistributedCluster", package: "swift-distributed-actors"),
            ],
            swiftSettings: swiftSettings
        ),
        .macro(
            name: "EventStoreAdapterSupportMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "EventStoreAdapterSupportMacroTests",
            dependencies: [
                "EventStoreAdapterSupportMacro",
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "MacroTesting", package: "swift-macro-testing"),
                .product(name: "DistributedCluster", package: "swift-distributed-actors"),
            ],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
    ]
}
