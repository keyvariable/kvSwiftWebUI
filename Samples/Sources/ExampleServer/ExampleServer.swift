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



@main
struct ExampleServer : KvServer {

    private let frontendBundle = try! KvHtmlBundle(rootView: { RootView() })


    // MARK: : KvServer

    var body: some KvResponseRootGroup {
        let ssl = try! ssl

        KvGroup(http: .v2(ssl: ssl), at: Host.current().addresses, on: [ 8080 ]) {
            KvGroup(httpMethods: .get) {
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
