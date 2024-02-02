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
//  KvScriptResource.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 01.02.2024.
//

import Foundation

import Crypto



// TODO: DOC
public struct KvScriptResource : Identifiable {

    var content: Content



    private init(content: Content) {
        self.content = content
    }



    // MARK: Fabrics

    /// - Returns: An instance from a string with source code.
    ///
    /// - Note: Script resource can be initialized from a string literal.
    public static func sourceCode(_ sourceCode: String) -> KvScriptResource {
        let hash = SHA256.hash(data: sourceCode.data(using: .utf8)!)

        return .init(content: .sourceCode(sourceCode, hash))
    }


    /// - Returns: An instance from a file.
    public static func url(_ url: URL) -> KvScriptResource {
        return .init(content: .url(url))
    }



    // MARK: .Content

    enum Content {

        /// Explicit source code and digest to be used as an ID.
        case sourceCode(String, SHA256.Digest)
        /// Content is at given URL. E.g. file resource in a bundle.
        case url(URL)

    }



    // MARK: : Identifiable

    public enum ID : Hashable {
        case digest(SHA256.Digest)
        case url(URL)
    }


    public var id: ID {
        switch content {
        case .sourceCode(_, let digest): .digest(digest)
        case .url(let url): .url(url)
        }
    }

}



// MARK: : ExpressibleByStringLiteral

extension KvScriptResource : ExpressibleByStringLiteral {

    public init(stringLiteral value: StringLiteralType) {
        self = .sourceCode(value)
    }

}



// MARK: : ExpressibleByStringInterpolation

extension KvScriptResource : ExpressibleByStringInterpolation { }
