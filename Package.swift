// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BorderBeamKit",
    platforms: [
        .iOS(.v17),
        // The Shader APIs need macOS 14, but the package links into apps that
        // deploy to macOS 13 (Threading), so the floor is 13 and every view is
        // annotated @available(macOS 14.0, *). BorderBeamHostView is the
        // AppKit seam such an app embeds behind its own availability check.
        .macOS(.v13),
    ],
    products: [
        .library(name: "BorderBeamKit", type: .static, targets: ["BorderBeamKit"])
    ],
    targets: [
        .target(
            name: "BorderBeamKit",
            resources: [
                .copy("Resources/beam-spec.json"),
                // Compiled into the bundle's default.metallib by Xcode's build
                // system (SwiftPM alone leaves it uncompiled — build the
                // package via Xcode for the shaders to work).
                .process("BeamShaders.metal"),
            ]
        ),
        .testTarget(
            name: "BorderBeamKitTests",
            dependencies: ["BorderBeamKit"]
        ),
    ]
)
