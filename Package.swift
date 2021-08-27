// swift-tools-version:5.1

import PackageDescription

let package = Package(name: "RosaKit",
                      platforms: [.iOS(.v9)],
                      products: [.library(name: "RosaKit",
                                          targets: ["RosaKit"])],
                      dependencies: [
                        .package(url: "https://github.com/dhrebeniuk/plain-pocketfft.git", from: "0.0.4")
                      ], targets: [.target(name: "RosaKit", dependencies: ["PlainPocketFFT"],
                                           path: "Sources")],
                      swiftLanguageVersions: [.v5])
