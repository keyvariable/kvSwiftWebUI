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
//  KvTestKit.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 23.01.2024.
//

import Foundation

@testable import kvSwiftWebUI



/// A collection of auxiliaries for testing.
struct KvTestKit { private init() { }

    /// - Returns: HTML code of given view.
    static func renderHTML<V : KvView>(for view: V) -> String {
        let context = KvHtmlRepresentationContext.root(
            html: .init(.init(),
                        cssAsset: .init(parent: nil),
                        rootPath: nil,
                        navigationPath: .empty,
                        localizationContext: .disabled)
        )

        var data = Data()

        KvHtmlRepresentation(of: view, in: context)
            .forEach { data.append($0) }

        return .init(data: data, encoding: .utf8)!
    }

}
