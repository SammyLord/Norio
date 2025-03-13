// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Norio",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "NorioCore",
            targets: ["NorioCore"]),
        .library(
            name: "NorioUI",
            targets: ["NorioUI"]),
        .library(
            name: "NorioExtensions",
            targets: ["NorioExtensions"]),
    ],
    dependencies: [
        // Dependencies here
    ],
    targets: [
        .target(
            name: "NorioCore",
            dependencies: []),
        .target(
            name: "NorioUI",
            dependencies: ["NorioCore"]),
        .target(
            name: "NorioExtensions",
            dependencies: ["NorioCore"]),
        .testTarget(
            name: "NorioCoreTests",
            dependencies: ["NorioCore"]),
        .testTarget(
            name: "NorioUITests",
            dependencies: ["NorioUI"]),
        .testTarget(
            name: "NorioExtensionsTests",
            dependencies: ["NorioExtensions"]),
    ]
) 