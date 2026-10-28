// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "HTTPRequestClient",
  platforms: [
    .macOS(.v15),
    .iOS(.v18),
    .watchOS(.v11),
    .tvOS(.v18),
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "HTTPRequestClient",
      targets: ["HTTPRequestClient"]
    )
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/indigo-ce/http-request-builder", from: "1.2.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "HTTPRequestClient",
      dependencies: [
        .product(name: "HTTPRequestBuilder", package: "http-request-builder"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "DependenciesMacros", package: "swift-dependencies"),
      ]
    ),
    .testTarget(
      name: "HTTPRequestClientTests",
      dependencies: ["HTTPRequestClient"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
