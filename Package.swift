// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftUIGlance",
  platforms: [.iOS(.v15)],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "SwiftUIGlance",
      targets: ["SwiftUIGlance"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/FluidGroup/swiftui-snap-dragging-modifier", from: "1.2.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftUIGlance",
      dependencies: [
        .product(name: "SwiftUISnapDraggingModifier", package: "swiftui-snap-dragging-modifier"),
      ]
    ),
    .testTarget(
      name: "SwiftUIGlanceTests",
      dependencies: ["SwiftUIGlance"]
    ),
  ]
)
