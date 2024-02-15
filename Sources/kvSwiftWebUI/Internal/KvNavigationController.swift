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
//  KvNavigationController.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 17.01.2024.
//

import Foundation

import Crypto
import kvHttpKit



struct KvNavigationController {

    let configuration: Configuration



    init<RootView : KvView>(for rootView: RootView, with configuration: Configuration) {
        self.configuration = configuration

        rootNodes = .for(rootView, with: configuration)
    }



    private let rootNodes: RootNodes



    // MARK: .Configuration

    struct Configuration {

        let rootPath: KvUrlPath?

        let iconHeaders: String?

        let assets: KvHtmlBundleAssets

        let localization: KvLocalization

    }



    // MARK: .RootNodes

    private enum RootNodes {

        /// Keys are the language tags.
        case localized([String : StaticNode])
        case `static`(StaticNode)


        // MARK: .Fabrics

        static func `for`<RootView : KvView>(_ rootView: RootView, with configuration: borrowing Configuration) -> RootNodes {
            var rootNodes: [String : StaticNode] = .init()

            configuration.localization.forEachLanguageTag { languageTag in
                rootNodes[languageTag] = .from(rootView, with: configuration, languageTag)
            }

            return switch rootNodes.isEmpty {
            case false: .localized(rootNodes)
            case true: .static(.from(rootView, with: configuration))
            }
        }


        // MARK: Subscripts

        subscript(representation: KvHtmlBundle.Representation) -> StaticNode? {
            switch self {
            case .localized(let nodes):
                let node = representation.languageTag.flatMap { nodes[$0] }
                assert(node != nil, "Internal inconsistency: language tag in \(representation) representation must match available localizations")
                return node

            case .static(let node):
                return node
            }
        }

    }



    // MARK: Operations

    func htmlResponse(for request: borrowing KvHtmlBundle.ProcessedRequest) -> KvHttpResponseContent? {
        guard var node = rootNodes[request.representation].map(AnyNode.staticNode(_:)) else { return nil }

        for component in request.path.components {
            guard let nextNode = node.next(for: String(component), with: configuration) else { return nil }

            node = nextNode
        }

        return node.htmlResponse(with: configuration)
    }



    // MARK: .AnyNode

    private enum AnyNode {

        case dynamicNode(Node)
        case staticNode(StaticNode)


        // MARK: Operations

        func next(for data: String, with configuration: borrowing Configuration) -> AnyNode? {
            switch self {
            case .staticNode(let node):
                node.next(for: data, with: configuration)

            case .dynamicNode(let node):
                node
                    .next(for: data, configuration: configuration)
                    .map(AnyNode.dynamicNode(_:))
            }
        }


        func htmlResponse(with configuration: borrowing Configuration) -> KvHttpResponseContent {
            switch self {
            case .dynamicNode(let node):
                KvNavigationController.htmlResponse(rootPath: configuration.rootPath, in: node.context, with: node.htmlRepresentation)

            case .staticNode(let node):
                node.httpResponse
            }
        }

    }



    // MARK: .Node

    private struct Node {

        typealias NavigationDestinations = KvEnvironmentValues.ViewConfiguration.NavigationDestinations


        let context: KvHtmlContext
        let htmlRepresentation: KvHtmlRepresentation


        init(_ body: KvHtmlBody,
             cssAsset: KvCssAsset,
             navigationPath: KvNavigationPath? = nil,
             configuration: borrowing Configuration,
             localizationContext: KvLocalization.Context
        ) {
            self.context = KvHtmlContext(
                configuration.assets,
                cssAsset: cssAsset,
                rootPath: configuration.rootPath,
                navigationPath: navigationPath ?? .init(elements: [ .init(value: .root, title: nil) ]),
                localizationContext: localizationContext,
                extraHeaders: configuration.iconHeaders.map { [ $0 ] }
            )

            self.htmlRepresentation = body.renderHTML(in: context)
        }


        // MARK: Operations

        /// A complete navigation path where last path component is updated with the node's title.
        var navigationPath: KvNavigationPath {
            var navigationPath = context.navigationPath
            navigationPath.updateLastElement(title: context.navigationTitle)
            return navigationPath
        }


        /// - Warning: path must be equal to the receiver's path with single extra component.
        func next(for data: String, configuration: borrowing Configuration) -> Node? {
            guard let destination = context.navigationDestinations?.destination(for: data) else { return nil }

            let body = destination.body

            return .init(body,
                         cssAsset: .init(parent: context.cssAsset.parent),
                         navigationPath: navigationPath + .component(rawValue: data, data: destination.value),
                         configuration: configuration,
                         localizationContext: context.localizationContext)
        }

    }



    // MARK: .StaticNode

    private class StaticNode {

        let httpResponse: KvHttpResponseContent

        let navigationDestinations: Node.NavigationDestinations?
        let navigationPath: KvNavigationPath

        let localizationContext: KvLocalization.Context

        /// It can be `nil` when there is no generated CSS.
        let cssAsset: KvCssAsset.Prototype?



        private init(from node: borrowing Node, with configuration: borrowing Configuration, cssAsset: KvCssAsset.Prototype?) {
            let context = node.context

            self.cssAsset = cssAsset

            httpResponse = KvNavigationController.htmlResponse(rootPath: configuration.rootPath, in: context, with: node.htmlRepresentation)

            navigationDestinations = context.navigationDestinations
            navigationPath = node.navigationPath

            localizationContext = context.localizationContext
        }



        private var childNodes: [String : StaticNode]?



        // MARK: Fabrics

        /// Traverses the static navigation destinations and returns the root node.
        static func from<Content : KvView>(_ view: Content, with configuration: borrowing Configuration, _ languageTag: String? = nil) -> StaticNode {
            let node = StaticNode.root(view, configuration: configuration, languageTag)

            node.processStaticDestinations(with: configuration)

            return node
        }


        private static func root<Content : KvView>(_ view: Content, configuration: borrowing Configuration, _ languageTag: String?) -> StaticNode {
            let localizationContext = configuration.localization.context(languageTag: languageTag)

            let node = Node(KvHtmlBodyImpl(content: view),
                            cssAsset: .init(parent: nil),
                            configuration: configuration,
                            localizationContext: localizationContext)

            // Caching the root CSS asset.
            var cssAssetPrototype: KvCssAsset.Prototype?
            replaceGeneratedCssWithResource(in: node.context, with: &cssAssetPrototype)

            return .init(from: node, with: configuration, cssAsset: cssAssetPrototype)
        }



        // MARK: Operations

        func next(for data: String, with configuration: borrowing Configuration) -> AnyNode? {
            if let childNode = childNodes?[data] {
                return .staticNode(childNode)
            }

            guard let destination = navigationDestinations?.destination(for: data) else { return nil }

            return .dynamicNode(Node(
                destination.body,
                cssAsset: .init(parent: cssAsset),
                navigationPath: navigationPath + .component(rawValue: data, data: destination.value),
                configuration: configuration,
                localizationContext: localizationContext
            ))
        }


        /// Processes all available static destinations recursively.
        private func processStaticDestinations(with configuration: borrowing Configuration) {
            navigationDestinations?.staticDestinations().forEach { destinationGroup in
                typealias DestinationNode = (node: Node, data: String)

                guard !destinationGroup.isEmpty else { return }

                let sharedCssAsset = KvCssAsset(parent: self.cssAsset)

                // Generating nodes.
                let seeds = destinationGroup.map { (data, destination) -> DestinationNode in
                    let node = Node(destination.body,
                                    cssAsset: sharedCssAsset,
                                    navigationPath: navigationPath + .component(rawValue: data, data: destination.value),
                                    configuration: configuration,
                                    localizationContext: localizationContext)
                    return (node, data)
                }
                _ = consume sharedCssAsset

                // Creation of static nodes.
                var sharedCssAssetPrototype: KvCssAsset.Prototype?

                seeds.forEach {
                    StaticNode.replaceGeneratedCssWithResource(in: $0.node.context, with: &sharedCssAssetPrototype)

                    let staticNode = StaticNode(from: $0.node, with: configuration, cssAsset: sharedCssAssetPrototype ?? cssAsset)

                    staticNode.processStaticDestinations(with: configuration)

                    insertChildNode(staticNode, for: $0.data)
                }
            }
        }


        private func insertChildNode(_ childNode: StaticNode, for data: String) {
            if childNodes == nil { childNodes = .init() }

            childNodes![data] = childNode
        }


        /// - Parameter cssAssetPrototype: Optional asset prototype to use.
        ///     If the prototype is available then it's applied.
        ///     Otherwise CSS prototype is generated and optionally saved at `cssAssetPrototype`.
        private static func replaceGeneratedCssWithResource(
            in context: KvHtmlContext,
            with cssAssetPrototype: inout KvCssAsset.Prototype?
        ) {
            if cssAssetPrototype == nil, !context.cssAsset.isEmpty {
                cssAssetPrototype = context.assets.insert(context.cssAsset)
            }

            guard let prototype = cssAssetPrototype else { return }

            context.unsafeReplaceCssAsset(with: prototype)
            context.insert(prototype)
        }

    }



    // MARK: Auxiliaries

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

        // TODO: Accumulate entire document inside KvHtmlRepresentation and perform simultanous accumulation of data from the the data list (from KvHtmlRepresentation) and evaluation of the hash digest.
        accumulator.append("<!DOCTYPE html><html\(context.localizationContext.languageTag.map { " lang=\"\($0)\"" } ?? "")><head>")
        do {
            let title: String? = context.navigationPath.elements
                .reversed()
                .lazy.compactMap { $0.title?.escapedPlainBytes(in: context.localizationContext) }
                .reduce(context.navigationTitle?.escapedPlainBytes(in: context.localizationContext)) {
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
        bodyRepresentation.forEach { accumulator.append($0) }
        accumulator.append("</html>")

        let (data, digest) = (consume accumulator).finalize()

        return .binary { data }
            .contentType(.text(.html))
            .contentLength(data.count)
            .entityTag(digest.withUnsafeBytes { KvHttpEntityTag.hex($0) })
    }

}
