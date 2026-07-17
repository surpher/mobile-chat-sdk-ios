// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HubspotMobileSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "HubspotMobileSDK",
            //type: .dynamic #Needed if distributing pre-compiled framework, but that's untested right now
            targets: ["HubspotMobileSDK"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "HubspotMobileSDK",
            resources: [
                .copy("Resources/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableExperimentalFeature("RegionBasedIsolation")
            ]
        ),
        .testTarget(
            name: "HubspotMobileSDKTests",
            dependencies: ["HubspotMobileSDK"]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
