// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Norio",
    platforms: [
        .macOS(.v13),
        .iOS(.v17),
    ],
    products: [
        .executable(
            name: "Norio",
            targets: ["Norio"]),
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
        .executableTarget(
            name: "Norio",
            dependencies: ["NorioUI"]),
        .target(
            name: "NorioCore",
            dependencies: []),
        .target(
            name: "NorioExtensions",
            dependencies: ["NorioCore"]),
        .target(
            name: "NorioUI",
            dependencies: ["NorioCore", "NorioExtensions"]),
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