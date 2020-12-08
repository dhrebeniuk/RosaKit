// swift-tools-version:5.1

import PackageDescription

let package = Package(name: "RosaKit",
                      platforms: [.iOS(.v8)],
                      products: [.library(name: "RosaKit",
                                          targets: ["RosaKit"])],
                      targets: [.target(name: "RosaKit",
                                        path: ".")],
                      swiftLanguageVersions: [.v5])
                      
