// swift-tools-version:5.9
// SaturdayCore — platform-independent brain of Saturday.
// Pure logic only: no UIKit/SwiftUI/AVFoundation/FoundationModels imports allowed here,
// so the whole package builds and tests on Linux/CI as well as on device.
import PackageDescription

let package = Package(
    name: "SaturdayCore",
    platforms: [
        .iOS(.v17), .watchOS(.v10), .macOS(.v14)
    ],
    products: [
        .library(name: "SaturdayCore", targets: ["SaturdayCore"])
    ],
    targets: [
        .target(name: "SaturdayCore"),
        .testTarget(name: "SaturdayCoreTests", dependencies: ["SaturdayCore"])
    ]
)
