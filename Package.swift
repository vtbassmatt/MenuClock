// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MenuClock",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MenuClock",
            targets: ["MenuClock"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MenuClock",
            exclude: ["Resources/Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/MenuClock/Resources/Info.plist"
                ])
            ]
        )
    ]
)
