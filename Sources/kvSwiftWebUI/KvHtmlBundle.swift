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
//  KvHtmlBundle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 25.10.2023.
//

import Crypto
import kvHttpKit



// TODO: DOC
public class KvHtmlBundle {

    // TODO: DOC
    public init<RootView : KvView>(at rootPath: KvUrlPath? = nil, icon: KvApplicationIcon? = nil, @KvViewBuilder rootView: @escaping () -> RootView) throws {
        self.rootPath = rootPath ?? .empty

        if let icon {
            context.insert(icon.htmlResources)

            if let htmlHeaders = icon.htmlHeaders {
                context.insert(headers: htmlHeaders)
            }
        }

        self.rootResponse = Self.response(staticBytes: KvHtmlDocument(rootView, in: context).representation(rootPath: rootPath))
            .contentType(.text(.html))

        do {
            var assets: [KvUrlPath.Slice : KvHttpResponseContent] = .init()

            try context.resources().forEach { resource in
                guard let content = resource.content else { return }

                var response: KvHttpResponseContent = switch content {
                case .bytes(let byteProvider):
                    Self.response(staticBytes: byteProvider())
                case .url(let url):
                    try .file(at: url)
                }

                if let contentType = resource.contentType {
                    response = response.contentType(contentType)
                }

                assets[.init(path: resource.uri)] = response
            }

            self.assets = consume assets
        }
    }



    private let rootPath: KvUrlPath
    private let context = KvHtmlContext()

    private let rootResponse: KvHttpResponseContent

    /// - Note: Slices are used as keys for compatibility with `kvServerKit/KvHttpResponse`.
    private let assets: [KvUrlPath.Slice : KvHttpResponseContent]



    // MARK: Operations

    /// See ``response(at:)-3g2a5`` for details.
    public func response(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        if path.isEmpty {
            return rootResponse
        }
        else {
            return assets[path]
        }
    }



    // MARK: Auxiliaries

    private static func response(staticBytes: KvHtmlBytes) -> KvHttpResponseContent {
        let (data, digest) = staticBytes.accumulate()

        return .binary { data }
            .contentLength(data.count)
            .entityTag(digest.withUnsafeBytes { KvHttpEntityTag.hex($0) })
    }

}
