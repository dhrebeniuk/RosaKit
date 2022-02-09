// swift-tools-version:5.1

import PackageDescription

let package = Package(name: "RosaKit",
                      platforms: [.iOS(.v9)],
                      products: [.library(name: "RosaKit",
                                          targets: ["RosaKit"])],
                      dependencies: [
                        .package(url: "https://github.com/dhrebeniuk/plain-pocketfft.git", .branch("main")),
                        .package(url: "https://github.com/dhrebeniuk/pocketfft.git", .branch("main")),
                      ], targets: [.target(name: "RosaKit", dependencies: ["PlainPocketFFTSwift", "PocketFFTSwift"],
                                           path: "Sources")],
                      swiftLanguageVersions: [.v5])
