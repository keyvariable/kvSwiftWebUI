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



struct KvHtmlResource {

    let content: Content
    let contentType: KvHttpContentType?



    init(content: Content, contentType: KvHttpContentType? = nil, headAttributes: Attributes? = nil) {
        self.content = content
        self.contentType = contentType
        self.headAttributes = headAttributes
    }



    /// Attributes used to synthesize a tag for HTML head section.
    private let headAttributes: Attributes?



    // MARK: Fabrics

    static func css(_ content: Content) -> KvHtmlResource {
        .init(content: content,
              contentType: .text(.css),
              headAttributes: .link(.init { $0[.linkRel] = "stylesheet" }))
    }


    static func externalScript(_ content: Content) -> KvHtmlResource {
        .init(content: content, contentType: .text(.javascript), headAttributes: .externalScript)
    }

    

    // MARK: .Content

    enum Content {

        /// - Parameter path: Path to refer to the resource. E.g. in HTML.
        case local(Source, KvUrlPath)

        case external(URL)


        var uri: Header.URI {
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



    // MARK: .Attributes

    enum Attributes {
        case externalScript
        case link(KvHtmlKit.Attributes)
    }



    // MARK: Operations

    var header: Header? {
        guard let headAttributes else { return nil }

        return switch headAttributes {
        case .externalScript:
            Header.externalScript(content.uri)
        case .link(let attributes):
            Header.link(content.uri, attributes)
        }
    }



    // MARK: .Header

    /// Representation of a resource that is used to synthesize the HTML code when the context is available. E.g. the base path.
    ///
    /// - Note: It conforms to `Identifiable` to be stored in the ordered set.
    enum Header : Identifiable {

        case externalScript(URI)
        case link(URI, KvHtmlKit.Attributes)


        // MARK: .URI

        enum URI : Hashable {

            case localPath(String)
            case url(URL)


            // MARK: HTML

            func setHref(to attributes: inout KvHtmlKit.Attributes, basePath: KvUrlPath?) {
                switch self {
                case .localPath(let path): attributes.set(href: path, relativeTo: basePath)
                case .url(let url): attributes.set(href: url)       // External resources are not resolved against basePath.
                }
            }


            func setSrc(to attributes: inout KvHtmlKit.Attributes, basePath: KvUrlPath?) {
                switch self {
                case .localPath(let path): attributes.set(src: path, relativeTo: basePath)
                case .url(let url): attributes.set(src: url)        // External resources are not resolved against basePath.
                }
            }

        }


        // MARK: : Identifiable

        var id: URI { uri }


        // MARK: : Equatable

        static func ==(lhs: Self, rhs: Self) -> Bool { lhs.uri == rhs.uri }


        // MARK: : Hashable

        func hash(into hasher: inout Hasher) {
            uri.hash(into: &hasher)
        }


        // MARK: Operations

        private var uri: URI {
            switch self {
            case .externalScript(let uri), .link(let uri, _): uri
            }
        }


        // MARK: HTML

        func html(basePath: KvUrlPath?) -> String {
            switch self {
            case .externalScript(let uri):
                return KvHtmlKit.Tag.script.html(attributes: .init { uri.setSrc(to: &$0, basePath: basePath) })

            case .link(let uri, var attributes):
                uri.setHref(to: &attributes, basePath: basePath)
                return KvHtmlKit.Tag.link.html(attributes: attributes)
            }
        }

    }

}
