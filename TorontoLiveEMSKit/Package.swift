// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TorontoLiveEMSKit",
    platforms: [
        // Deliberately below the app's own 26.6 deployment target. The app's
        // IPHONEOS_DEPLOYMENT_TARGET and MACOSX_DEPLOYMENT_TARGET govern what actually
        // ships, so a lower library minimum changes nothing — and a manifest declaring
        // tools-version 6.0 cannot name `.v26`, which arrived in a later
        // PackageDescription. The versions below are safe on any toolchain that
        // understands tools-version 6.0.
        .iOS(.v18),
        .macOS(.v15),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "TorontoLiveEMSKit",
            targets: ["TorontoLiveEMSKit"]
        ),
    ],
    targets: [
        .target(name: "TorontoLiveEMSKit"),
        .testTarget(
            name: "TorontoLiveEMSKitTests",
            dependencies: ["TorontoLiveEMSKit"]
        ),
    ]
)
