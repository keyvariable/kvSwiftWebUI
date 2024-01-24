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
//  ExampleServer.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.10.2023.
//

import Foundation

import kvSwiftWebUI

import kvServerKit



/// HTTP server based on [kvServerKit](https://github.com/keyvariable/kvServerKit.swift.git) framework.
/// Also it's used as the application entry point.
///
/// - Note: Generally any server can be used.
@main
struct ExampleServer : KvServer {

    /// An HTML bundle generated from ``RootView``.
    ///
    /// HTML bundle manages HTML representations of view hierarchy and the assets and provides HTML responses via `KvHtmlBundle.response(at:)` method.
    /// For example, HTML response of the root view is returned for empty path, response of purple color view is returned for `colors/purple` path.
    private let frontendBundle = try! KvHtmlBundle(rootView: { RootView() })


    // MARK: : KvServer

    var body: some KvResponseRootGroup {
        let ssl = try! ssl

        /// This declaration means that server uses HTTP/2.0 with self-signed certificate
        /// and listens for connections on all available IP-addresses on 8080 port.
        KvGroup(http: .v2(ssl: ssl), at: Host.current().addresses, on: [ 8080 ]) {
            /// Contents of this group are responded on GET and HEAD requests.
            KvGroup(httpMethods: .get) {
                /// This declaration is an HTTP response at the root path with contents of *frontendBundle*.
                /// The subpath is equal to whole URL path due to response is declared at the root.
                KvHttpResponse.with
                    .subpathFlatMap { .unwrapping(frontendBundle.response(at: $0)) }
                    .content { input in input.subpath }
            }
        }
    }


    /// In this example self-signed certificate from the bundle is used to provide HTTPs.
    ///
    /// - Warning: Don't use this certificate in your projects.
    private var ssl: KvHttpChannel.Configuration.SSL {
        get throws {
            let pemPath = Bundle.module.url(forResource: "https", withExtension: "pem")!.path

            return try .init(pemPath: pemPath)
        }
    }

}
