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
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MenuClock",
            dependencies: ["Yams"],
            exclude: ["Resources/"],
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
