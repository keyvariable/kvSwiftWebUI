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

import Crypto
import kvHttpKit



struct KvHtmlResource : Hashable {

    let content: Content
    let contentType: KvHttpContentType?

    /// Attributes of link tag for the resource.
    ///
    /// - Note: `Href` attribute is inserted automatically.
    let linkAttributes: [KvHtmlKit.Attribute]?



    init(content: Content, contentType: KvHttpContentType? = nil, linkAttributes: [KvHtmlKit.Attribute]? = nil) {
        self.content = content
        self.contentType = contentType
        self.linkAttributes = linkAttributes
    }



    // MARK: Fabrics

    static func css(_ content: Content) -> Self {
        .init(content: content, contentType: .text(.css), linkAttributes: [ .linkRel("stylesheet") ])
    }

    

    // MARK: .Content

    enum Content {

        /// - Parameter path: Path to refer to the resource. E.g. in HTML.
        case local(Source, KvUrlPath)

        case external(URL)


        var uri: HtmlLink.URI {
            switch self {
            case .local(_, let path): .localPath(path.joined)
            case .external(let url): .url(url)
            }
        }


        // MARK: .Source

        enum Source {

            /// Data and hash to be used as the entity tag.
            case data(Data, SHA256.Digest)
            /// URL to resource at the server.
            case url(URL)

        }

    }



    // MARK: : Equatable

    static func ==(lhs: Self, rhs: Self) -> Bool { lhs.content.uri == rhs.content.uri }



    // MARK: : Hashable

    func hash(into hasher: inout Hasher) {
        content.uri.hash(into: &hasher)
    }



    // MARK: Operations

    var htmlLink: HtmlLink? {
        guard let linkAttributes else { return nil }

        return .init(uri: content.uri, linkAttributes: linkAttributes)
    }



    // MARK: .HtmlLink

    struct HtmlLink : Hashable {

        let uri: URI
        let linkAttributes: [KvHtmlKit.Attribute]


        // MARK: .URI

        enum URI : Hashable, Comparable {

            case localPath(String)
            case url(URL)


            // MARK: : Comparable

            static func <(lhs: Self, rhs: Self) -> Bool {

                func RawValue(_ uri: Self) -> String {
                    switch uri {
                    case .localPath(let string): string
                    case .url(let url): url.absoluteString
                    }
                }

                return RawValue(lhs) < RawValue(rhs)
            }
        }


        // MARK: : Equatable

        static func ==(lhs: Self, rhs: Self) -> Bool { lhs.uri == rhs.uri }


        // MARK: : Hashable

        func hash(into hasher: inout Hasher) {
            uri.hash(into: &hasher)
        }


        // MARK: Operations

        func bytes(basePath: KvUrlPath?) -> KvHtmlBytes {
            let href: KvHtmlKit.Attribute = switch uri {
            case .localPath(let path): .href(path, relativeTo: basePath)
            case .url(let url): .href(url)      // External resources are not resolved against basePath.
            }

            return .tag(.link, attributes: [ linkAttributes, [ href ] ].joined())
        }

    }

}
