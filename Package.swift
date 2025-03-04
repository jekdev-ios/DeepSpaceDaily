//
//  Package.swift
//  DeepSpaceDaily
//
//  Created by admin on 29/02/25.
//

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DeepSpaceDaily",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DeepSpaceDaily",
            targets: ["DeepSpaceDaily"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DeepSpaceDaily"),
        .testTarget(
            name: "DeepSpaceDailyTests",
            dependencies: ["DeepSpaceDaily"]
        ),
    ]
)
