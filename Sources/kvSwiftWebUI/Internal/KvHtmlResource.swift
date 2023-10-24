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
//  KvHtmlResource.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.11.2023.
//

import Foundation

import kvHttpKit



struct KvHtmlResource : Hashable {

    /// If `nil` then resource is processed as external.
    let content: Content?
    let contentType: KvHttpContentType?

    /// Path to refer to the resource. E.g. in HTML.
    let uri: String

    /// Attributes of link tag for the resource.
    ///
    /// - Note: `Href` attribute is inserted automatically.
    let linkAttributes: [KvHtmlKit.Attribute]?



    init(content: Content? = nil, contentType: KvHttpContentType? = nil, uri: String, linkAttributes: [KvHtmlKit.Attribute]? = nil) {
        self.content = content
        self.contentType = contentType
        self.uri = uri
        self.linkAttributes = linkAttributes
    }



    // MARK: .Content

    enum Content {

        case bytes(() -> KvHtmlBytes)
        /// URL to resource at the server.
        case url(URL)

    }



    // MARK: Fabrics

    static func css(_ content: Content? = nil, uri: String) -> Self {
        .init(content: content, contentType: .text(.css), uri: uri, linkAttributes: [ .linkRel("stylesheet") ])
    }



    // MARK: : Equatable

    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.uri == rhs.uri
    }



    // MARK: : Hashable

    func hash(into hasher: inout Hasher) {
        uri.hash(into: &hasher)
    }



    // MARK: Operations

    /// - Returns: &lt;link&gt; tag bytes.
    func linkHtmlBytes(relativeTo basePath: KvUrlPath? = nil) -> KvHtmlBytes? {
        // Resources with no `linkAttributes` are not linked to HTML document via <link> tags in the head.
        guard let linkAttributes = linkAttributes else { return nil }

        let href: KvHtmlKit.Attribute = switch content != nil {
        case true: .href(uri, relativeTo: basePath)
        case false: .href(.from(uri))       // Contentless (external) resources are not resolved against basePath.
        }

        return .tag(.link, attributes: [ linkAttributes, [ href ] ].joined())
    }

}
