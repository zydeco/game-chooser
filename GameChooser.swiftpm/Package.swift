// swift-tools-version: 5.9

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "GameChooser",
    platforms: [
        .iOS("17.2")
    ],
    products: [
        .iOSApplication(
            name: "GameChooser",
            targets: ["AppModule"],
            bundleIdentifier: "net.namedfork.boardgamechooser",
            teamIdentifier: "UJXNDZ5TNU",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ],
            appCategory: .boardGames
        )
    ],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/XMLCoder.git", "0.17.1"..<"1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "XMLCoder", package: "xmlcoder")
            ],
            path: ".",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)