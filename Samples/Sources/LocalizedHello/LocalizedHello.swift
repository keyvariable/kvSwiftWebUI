//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  LocalizedHello.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.02.2024.
//

import Foundation

import kvSwiftWebUI
import kvSwiftWebUI_kvServerKit

import kvServerKit



/// See source code of *ExampleServer* target for detailed comments.
///
/// Use "lang" URL query item to request particular localization.
/// For example, visit "https://localhost:8080?lang=zh-Hant" for traditional Chinese localization.
@main
struct LocalizedHello : KvServer {

    private let frontendBundle = try! KvHttpBundle(
        with: .init(defaultBundle: .module),
        rootView: { LocalizedHelloView() }
    )


    // MARK: : KvServer

    var body: some KvResponseRootGroup {
        let ssl = try! ssl

        KvGroup(http: .v2(ssl: ssl), at: Host.current().addresses, on: [ 8080 ]) {
            frontendBundle
        }
    }


    private var ssl: KvHttpChannel.Configuration.SSL {
        get throws {
            let pemPath = Bundle.module.url(forResource: "https", withExtension: "pem")!.path

            return try .init(pemPath: pemPath)
        }
    }

}
