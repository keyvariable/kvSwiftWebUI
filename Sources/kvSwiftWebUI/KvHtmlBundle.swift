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

import Foundation

import CryptoKit
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

            let rootContext = KvHtmlContext(assets, rootPath: rootPath, navigationPath: .init(), extraHeaders: iconHeaders.map { [ $0 ] })

            // Root body is rendered to fill context.
            _ = KvHtmlBodyImpl(content: rootView()).renderHTML(in: rootContext)

            self.cssAssets = .init(rootContext.makeCssResource())
        }
    }



    private let rootPath: KvUrlPath?

    private let iconHeaders: String?

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



            init(body: KvHtmlBody, assets: KvHtmlBundleAssets, cssAssets: CssAssets?, rootPath: KvUrlPath?, iconHeaders: String?) {
                let context = KvHtmlContext(assets, cssAsset: cssAssets?.payload, rootPath: rootPath, navigationPath: .init(), extraHeaders: iconHeaders.map { [ $0 ] })
                let representation = body.renderHTML(in: context)

                self.init(body: body, cssAssets: cssAssets, iconHeaders: iconHeaders, representation: representation, context: context)
            }


            private init(body: KvHtmlBody, cssAssets: CssAssets?, iconHeaders: String?, representation: KvHtmlRepresentation, context: KvHtmlContext) {
                self.body = body
                self.cssAssets = cssAssets
                self.iconHeaders = iconHeaders
                self.representation = representation
                self.context = context
            }


            private let body: KvHtmlBody
            private let cssAssets: CssAssets?

            private let iconHeaders: String?


            // MARK: Operations

            /// - Warning: path must be equal to the receiver's path with single extra component.
            func next(for data: Substring) -> Self? {
                let data = String(data)

                guard let destination = representation.navigationDestinations?.destination(for: data) else { return nil }

                let body = destination.body
                let cssAssets = cssAssets?[data]
                var navigationPath = context.navigationPath

                navigationPath.append(.init(rawValue: data, data: destination.value, title: representation.navigationTitle))

                let context = KvHtmlContext(
                    context.assets,
                    cssAsset: cssAssets?.payload ?? context.cssAsset.parent,
                    rootPath: context.rootPath,
                    navigationPath: navigationPath,
                    extraHeaders: iconHeaders.map { [ $0 ] }
                )
                let representation = body.renderHTML(in: context)

                return .init(body: body, cssAssets: cssAssets, iconHeaders: iconHeaders, representation: representation, context: context)
            }

        }


        var node = NavigationNode(body: rootBody, assets: assets, cssAssets: cssAssets, rootPath: rootPath, iconHeaders: iconHeaders)

        for component in path.components {
            guard let nextNode = node.next(for: component) else { return nil }

            node = nextNode
        }

        return htmlResponse(in: node.context, with: node.representation)
    }


    private static func htmlResponse(rootPath: KvUrlPath?, in context: KvHtmlContext, with bodyRepresentation: KvHtmlRepresentation) -> KvHttpResponseContent {
        
        struct Accumulator {

            private var data: Data = .init()
            private var hasher: SHA256 = .init()


            consuming func finalize() -> (Data, SHA256.Digest) { (data, hasher.finalize()) }

            mutating func append(_ data: Data) {
                self.data.append(data)
                hasher.update(data: data)
            }

            mutating func append<S>(_ data: S) where S : Sequence, S.Element == Data { data.forEach { append($0) } }

            mutating func append(_ string: String) { append(string.data(using: .utf8)!) }

            mutating func append(_ string: String?) {
                guard let string else { return }
                append(string)
            }

            mutating func append(_ strings: String?...) {
                strings.forEach {
                    guard let string = $0 else { return }
                    append(string)
                }
            }

        }


        var accumulator = Accumulator()

        // TODO: Accumulate entire document inside KvHtmlRepresentation and perform hashing with the data list resolvation.
        accumulator.append("<!DOCTYPE html><html><head>")
        do {
            let title: String? = context.navigationPath.elements
                .reversed()
                .lazy.compactMap { $0.title?.escapedPlainBytes }
                .reduce(bodyRepresentation.navigationTitle?.escapedPlainBytes) {
                    $0 != nil ? "\($0!) | \($1)" : $1
                }
                .map { "<title>\($0)</title>" }

            accumulator.append(title)
        }
        accumulator.append(
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
            "<meta name=\"format-detection\" content=\"telephone=no\" /><meta name=\"format-detection\" content=\"date=no\" /><meta name=\"format-detection\" content=\"address=no\" /><meta name=\"format-detection\" content=\"email=no\" />",
            context.headers,
            "</head>"
        )
        accumulator.append(IteratorSequence(bodyRepresentation.makeDataIterator()))
        accumulator.append("</html>")

        let (data, digest) = (consume accumulator).finalize()

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
