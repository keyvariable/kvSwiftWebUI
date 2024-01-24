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
//  KvHtmlBundleAssets.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 29.12.2023.
//

import Foundation

import Crypto
import kvHttpKit
import kvKit



/// - Note: It's a class to provide copy-by-reference semantic.
class KvHtmlBundleAssets {

    private let mutationLock = NSLock()

    /// - Note: Slices are used as keys for compatibility with `kvServerKit/KvHttpResponse`.
    private var responses: [KvUrlPath.Slice : KvHttpResponseContent] = .init()



    // MARK: Subscripts

    subscript(path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        mutationLock.withLock { responses[path] }
    }



    // MARK: Operations

    /// Inserts local resources into the receiver.
    func insert(_ resource: KvHtmlResource) {
        guard case .local(let source, let path) = resource.content else { return }

        let key = KvUrlPath.Slice(consume path)

        guard mutationLock.withLock({ responses[key] == nil }) else { return }

        var response: KvHttpResponseContent

        switch source {
        case .data(let data, let digest):
            response = .binary { data }
                .contentLength(data.count)
                .entityTag(digest.withUnsafeBytes { KvHttpEntityTag.hex($0) })

        case .url(let url):
            response = (try? .file(at: url)) ?? .internalServerError
        }

        if let contentType = resource.contentType {
            response = response.contentType(contentType)
        }

        mutationLock.withLock {
            responses[key] = response
        }
    }


    /// Inserts local resource created from given CSS asset.
    ///
    /// - Returns: A CSS asset prototype referencing to created resource.
    func insert(_ cssAsset: KvCssAsset) -> KvCssAsset.Prototype {
        let data = cssAsset.css.data(using: .utf8)!
        let digest = SHA256.hash(data: data)

        let id = digest.withUnsafeBytes {
            KvBase64.encodeAsString($0, alphabet: .urlSafe)
        }

        let resource: KvHtmlResource = .css(.local(.data(data, digest), .init(path: "\(id).css")))
        let prototype = cssAsset.asPrototype(resource: resource)

        insert(resource)

        return prototype
    }

}
