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

import kvHttpKit



// TODO: DOC
public class KvHtmlBundle {

    // TODO: DOC
    public init<RootView : KvView>(at rootPath: KvUrlPath? = nil, icon: KvApplicationIcon? = nil, @KvViewBuilder rootView: @escaping () -> RootView) throws {
        self.rootPath = rootPath

        icon?.htmlResources.forEach(assets.insert(_:))
        iconHeaders = icon?.htmlHeaders

        do {
            self.rootBody = KvHtmlBodyImpl(content: rootView())

            let rootContext = KvHtmlContext(assets, rootPath: rootPath, navigationPath: [ ], extraHeaders: iconHeaders)

            // Root body is rendered to fill context.
            _ = KvHtmlBodyImpl(content: rootView()).renderHTML(in: rootContext)

            self.cssAssets = .init(rootContext.makeCssResource())
        }
    }



    private let rootPath: KvUrlPath?

    private let iconHeaders: KvHtmlBytes?

    private let rootBody: KvHtmlBody

    private let assets = KvHtmlBundleAssets()

    private let cssAssets: CssAssets



    // MARK: Operations

    /// See ``response(at:)-3g2a5`` for details.
    public func response(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        htmlResponse(at: path)
        ?? assets[path]
    }


    private func htmlResponse(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {

        struct NavigationNode {

            let representation: KvHtmlRepresentation
            let context: KvHtmlContext



            init(body: KvHtmlBody, assets: KvHtmlBundleAssets, cssAssets: CssAssets?, rootPath: KvUrlPath?, iconHeaders: KvHtmlBytes?) {
                let context = KvHtmlContext(assets, cssAsset: cssAssets?.payload, rootPath: rootPath, navigationPath: [ ], extraHeaders: iconHeaders)
                let representation = body.renderHTML(in: context)

                self.init(body: body, cssAssets: cssAssets, iconHeaders: iconHeaders, representation: representation, context: context)
            }


            private init(body: KvHtmlBody, cssAssets: CssAssets?, iconHeaders: KvHtmlBytes?, representation: KvHtmlRepresentation, context: KvHtmlContext) {
                self.body = body
                self.cssAssets = cssAssets
                self.iconHeaders = iconHeaders
                self.representation = representation
                self.context = context
            }


            private let body: KvHtmlBody
            private let cssAssets: CssAssets?

            private let iconHeaders: KvHtmlBytes?


            // MARK: Operations

            #warning("Refactor unsafe argument")
            /// - Warning: path must be equal to the receiver's path with single extra component.
            func next(at path: KvUrlPath.Slice) -> Self? {
                let data = String(path.components.last!)

                guard let body = representation.navigationDestinations?.destination(for: data) else { return nil }

                let cssAssets = cssAssets?[data]

                let context = KvHtmlContext(
                    context.assets,
                    cssAsset: cssAssets?.payload ?? context.cssAsset.parent,
                    rootPath: context.rootPath,
                    navigationPath: path,
                    extraHeaders: iconHeaders
                )
                let representation = body.renderHTML(in: context)

                return .init(body: body, cssAssets: cssAssets, iconHeaders: iconHeaders, representation: representation, context: context)
            }

        }


        var node = NavigationNode(body: rootBody, assets: assets, cssAssets: cssAssets, rootPath: rootPath, iconHeaders: iconHeaders)

        for index in 0..<path.components.count {
            guard let nextNode = node.next(at: path.prefix(index + 1)) else { return nil }

            node = nextNode
        }

        return htmlResponse(in: node.context, with: node.representation)
    }


    private static func htmlResponse(rootPath: KvUrlPath?, in context: KvHtmlContext, with bodyRepresentation: KvHtmlRepresentation) -> KvHttpResponseContent {
        let (data, digest) = KvHtmlDocument.htmlBytes(headers: context.headers, with: bodyRepresentation)
            .accumulate()

        return .binary { data }
            .contentType(.text(.html))
            .contentLength(data.count)
            .entityTag(digest.withUnsafeBytes { KvHttpEntityTag.hex($0) })
    }


    private func htmlResponse(in context: KvHtmlContext, with bodyRepresentation: KvHtmlRepresentation) -> KvHttpResponseContent {
        Self.htmlResponse(rootPath: rootPath, in: context, with: bodyRepresentation)
    }



    // MARK: .CssAssets

    private class CssAssets {

        let payload: KvCssAsset.Prototype


        init(_ payload: KvCssAsset.Prototype) {
            self.payload = payload
        }


        private var childNodes: [String : CssAssets] = .init()


        // MARK: Operations

        subscript(key: String) -> CssAssets? { childNodes[key] }


        func updateValue(_ payload: KvCssAsset.Prototype, forKey key: String) {
            assert(payload.parent === payload)

            childNodes[key] = .init(payload)
        }

    }

}
