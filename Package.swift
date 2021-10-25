// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "jlsftp",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13),
		.watchOS(.v6),
		.tvOS(.v13),
	],
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "jlsftp",
			targets: ["jlsftp"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		// .package(url: /* package url */, from: "1.0.0"),
		.package(url: "https://github.com/apple/swift-nio.git", .exact("2.33.0")),
		.package(url: "https://github.com/apple/swift-nio-extras.git", .exact("1.10.2")),
		.package(url: "https://github.com/apple/swift-nio-ssh", .exact("0.3.3")),
		.package(url: "https://github.com/apple/swift-log.git", .exact("1.4.2")),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "jlsftp",
			dependencies: [
				.product(name: "NIO", package: "swift-nio"),
				.product(name: "NIOConcurrencyHelpers", package: "swift-nio"),
				.product(name: "NIOExtras", package: "swift-nio-extras"),
				.product(name: "NIOSSH", package: "swift-nio-ssh"),
				.product(name: "Logging", package: "swift-log"),
			]
		),
		.target(name: "jlsftpSimpleSSHClient", dependencies: [
			"jlsftp",
			.product(name: "NIO", package: "swift-nio"),
			.product(name: "NIOSSH", package: "swift-nio-ssh"),
		]),
		.target(name: "jlsftpSimpleSSHServer", dependencies: [
			"jlsftp",
			.product(name: "NIO", package: "swift-nio"),
			.product(name: "NIOSSH", package: "swift-nio-ssh"),
		]),
		.testTarget(
			name: "jlsftpTests",
			dependencies: [
				"jlsftp",
				.product(name: "NIOTestUtils", package: "swift-nio"),
			]
		),
	]
)
