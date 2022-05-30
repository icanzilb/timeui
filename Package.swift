// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "timeui",
    platforms: [.macOS(.v11)],
    products: [.executable(name: "timeui", targets: ["timeui"])],
    targets: [
        .executableTarget(
            name: "test-app"
        ),
        .executableTarget(
            name: "timeui",
            linkerSettings: [
                .unsafeFlags(
                    ["-Xlinker", "-sectcreate",
                     "-Xlinker", "__TEXT",
                     "-Xlinker", "__info_plist",
                     "-Xlinker", "Resources/Info.plist"
                    ]
                )
            ]
        ),
        .testTarget(
            name: "timeuiTests",
            dependencies: ["timeui"]
        ),
    ]
)
