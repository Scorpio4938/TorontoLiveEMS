// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TorontoLiveEMSKit",
    platforms: [
        // The iPhone and macOS targets are the app's; the app's own
        // IPHONEOS_DEPLOYMENT_TARGET / MACOSX_DEPLOYMENT_TARGET (26.6) governs what
        // actually ships, so a library minimum of 26.0 is correct here.
        //
        // If your toolchain's PackageDescription predates iOS 26 and rejects `.v26`,
        // replace these with `.iOS(.v18), .macOS(.v15)` — the app's own deployment
        // target still applies, so nothing changes downstream.
        .iOS(.v26),
        .macOS(.v26),
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
