// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "jlsftp",
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "jlsftp",
			targets: ["jlsftp"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
		.package(url: "https://github.com/apple/swift-nio-extras.git", from: "1.0.0"),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "jlsftp",
			dependencies: [
				.product(name: "NIO", package: "swift-nio"),
				.product(name: "NIOExtras", package: "swift-nio-extras"),
			]
		),
		.testTarget(
			name: "jlsftpTests",
			dependencies: [
				"jlsftp",
			]
		),
	]
)
