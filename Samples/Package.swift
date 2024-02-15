// swift-tools-version:5.9
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
//
//  Package.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.10.2023.
//

import PackageDescription


let package = Package(
    name: "Samples-kvSwiftWebUI",

    defaultLocalization: "en",

    platforms: [ .macOS(.v13), ],

    products: [ .executable(name: "ExampleServer", targets: [ "ExampleServer" ]),
                .executable(name: "LocalizedHello", targets: [ "LocalizedHello" ]),
    ],

    dependencies: [ .package(path: "../"),
                    .package(url: "https://github.com/keyvariable/kvServerKit.swift.git", from: "0.6.0")
    ],

    targets: [
        .executableTarget(
            name: "ExampleServer",
            dependencies: [ .product(name: "kvSwiftWebUI", package: "kvSwiftWebUI"),
                            .product(name: "kvSwiftWebUI_kvServerKit", package: "kvSwiftWebUI"),
                            .product(name: "kvServerKit", package: "kvServerKit.swift")
            ],
            resources: [ .copy("Resources/https.pem"),
                         .copy("Resources/img"),
                         .copy("Resources/js"),
            ]
        ),
        .executableTarget(
            name: "LocalizedHello",
            dependencies: [ .product(name: "kvSwiftWebUI", package: "kvSwiftWebUI"),
                            .product(name: "kvSwiftWebUI_kvServerKit", package: "kvSwiftWebUI"),
                            .product(name: "kvServerKit", package: "kvServerKit.swift")
            ],
            resources: [ .copy("Resources/https.pem"),
                         .process("Resources/Localizable.xcstrings"),
            ]
        )
    ]
)
