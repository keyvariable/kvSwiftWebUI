// swift-tools-version: 5.9
//
//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2023 Svyatoslav Popov (info@keyvar.com).
//
//  This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
//  License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any
//  later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
//  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program.
//  If not, see <https://www.gnu.org/licenses/>.
//
//  SPDX-License-Identifier: GPL-3.0-or-later
//
//===----------------------------------------------------------------------===//

import PackageDescription


let swiftSettings: [SwiftSetting]? = nil


let package = Package(
    name: "kvSwiftWebUI",

    platforms: [ .macOS(.v13) ],

    products: [ .library(name: "kvSwiftWebUI", targets: [ "kvSwiftWebUI" ]),
                .library(name: "kvCssKit", targets: [ "kvCssKit" ]),],

    dependencies: [ .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
                    .package(url: "https://github.com/keyvariable/kvKit.swift.git", from: "4.8.0"),
                    .package(url: "https://github.com/keyvariable/kvServerKit.swift.git", from: "0.11.0"),
                    .package(url: "https://github.com/keyvariable/kvSIMD.swift.git", from: "1.0.2"), ],

    targets: [
        .target(name: "kvCssKit",
                swiftSettings: swiftSettings),

        .target(name: "kvSwiftWebUI",
                dependencies: [ "kvCssKit",
                                .product(name: "Crypto", package: "swift-crypto"),
                                .product(name: "kvHttpKit", package: "kvServerKit.swift"),
                                .product(name: "kvKit", package: "kvKit.swift"),
                                .product(name: "kvSIMD", package: "kvSIMD.swift"), ],
                resources: [ .copy("Resources/html") ],
                swiftSettings: swiftSettings),

        .testTarget(name: "kvSwiftWebUITests",
                    dependencies: [ "kvSwiftWebUI" ],
                    swiftSettings: swiftSettings),
    ]
)
