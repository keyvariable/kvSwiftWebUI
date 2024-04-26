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
//  KvHttpBundle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 25.10.2023.
//

import Foundation

import kvHttpKit
import kvKit



/// *KvHttpBundle* resolves the root view to collection HTTP responses including HTML, styles, resources, etc.
///
/// When bundle is initialized, use ``response(for:)`` or ``response(at:as:)`` methods to process requests and get responses.
///
/// By default it's assumed that bundle is served to the domain's root path and maximum size of response cache is 50% of physical memory on the machine.
/// Use ``Configuration`` structure and ``init(with:rootView:)`` initializer to customize bundle.
///
/// When the responses are served with [kvServerKit](https://github.com/keyvariable/kvServerKit.swift.git ),
/// bundles can be used as the response expressions:
/// ```swift
/// import kvServerKit
/// import kvSwiftWebUI
/// import kvSwiftWebUI_kvServerKit
///
/// @main
/// struct ExampleServer : KvServer {
///     private let bundle: KvHttpBundle = <#...#>
///
///     var body: some KvResponseRootGroup {
///         KvGroup(http: .v1_1(), at: Host.current().addresses, on: [ 8080 ]) {
///             bundle
///         }
///     }
/// }
/// ```
public class KvHttpBundle {

    /// A shorthand for ``init(with:rootView:)``.
    @inlinable
    convenience public init<RootView>(
        at rootPath: KvUrlPath? = nil,
        icon: KvApplicationIcon? = nil,
        @KvViewBuilder rootView: @escaping () -> RootView
    ) throws
    where RootView : KvView
    {
        try self.init(with: .init(rootPath: rootPath, icon: icon), rootView: rootView)
    }


    /// Resolves given *rootView* and initializes bundle with the result and given *configuration*.
    public init<RootView>(with configuration: borrowing Configuration, @KvViewBuilder rootView: @escaping () -> RootView) throws
    where RootView : KvView
    {
        localization = .init(configuration.defaultBundle ?? .main)

        configuration.icon?.forEachHtmlResource(assets.insert(_:))

        responseCache = configuration.responseCacheSize.map {
            .init(maximumByteSize: $0.value)
        }

        navigationController = .init(
            for: rootView(),
            with: .init(rootPath: configuration.rootPath,
                        iconHeaders: configuration.icon?.htmlHeaders,
                        assets: assets,
                        localization: localization,
                        defaultBundle: configuration.defaultBundle,
                        authorsTag: configuration.authorsTag)
        )

        do {
            let navigationController = navigationController
            // - NOTE: Catching reference to `self` is avoided to prevent retain cycle.
            responseBlock = { navigationController.htmlResponse(for: $0) }
        }
    }



    private let assets = KvHttpBundleAssets()
    private let localization: KvLocalization

    private let navigationController: KvNavigationController

    private let responseCache: KvHttpResponseCache<ProcessedRequest>?
    /// A block to be used to synthesize response when there is no cached value.
    private let responseBlock: (borrowing ProcessedRequest) -> KvHttpResponseContent?



    // MARK: .Configuration

    public struct Configuration {

        /// A path on the server the root view is served at. Empty or `nil` values mean that the root view is served at "/" path.
        public var rootPath: KvUrlPath?

        /// An icon to be used in browser UI, on OS home screens, etc.
        public var icon: KvApplicationIcon?

        /// Maximum size of cached responses. If `nil` then the cache is disabled. By default cache uses 50% of physical memory on the machine.
        public var responseCacheSize: ResponseCacheSize?

        /// Default bundle to use when `nil` bundle is passed as an argument. If `nil` then `.main` bundle is used.
        ///
        /// For example, this property can be used to reduce explicit passing of `.module` bundle to texts, images, etc.
        ///
        /// - SeeAlso: ``KvView/defaultBundle(_:)``.
        public var defaultBundle: Bundle?

        /// A text to be used as the author's tag.
        public var authorsTag: KvText?



        /// - Parameters:
        ///   - rootPath: Initial value for ``rootPath`` property.
        ///   - icon: Initial value for ``icon`` property.
        ///   - responseCacheSize: Initial value for ``responseCacheSize`` property.
        ///   - defaultBundle: Initial value for ``defaultBundle`` property.
        ///   - authorsTag: Initial value for ``authorsTag`` property.
        @inlinable
        public init(rootPath: KvUrlPath? = nil,
                    icon: KvApplicationIcon? = nil,
                    responseCacheSize: ResponseCacheSize? = .physicalMemoryRatio(0.5),
                    defaultBundle: Bundle? = nil,
                    authorsTag: KvText? = nil
        ) {
            self.rootPath = rootPath
            self.icon = icon
            self.responseCacheSize = responseCacheSize
            self.defaultBundle = defaultBundle
            self.authorsTag = authorsTag
        }


        // MARK: .ResponseCacheSize

        public enum ResponseCacheSize : ExpressibleByIntegerLiteral {

            /// Number bytes to be used as maximum size of the response cache.
            case byteSize(UInt64)
            /// Ratio of physical memory on the machine. E.g. `.physicalMemoryRatio(0.5)` means 50% of the physical memory size.
            case physicalMemoryRatio(Double)


            // MARK: : ExpressibleByIntegerLiteral

            public init(integerLiteral value: IntegerLiteralType) {
                self = .byteSize(numericCast(value))
            }


            // MARK: Operations

            var value: UInt64 {
                switch self {
                case .byteSize(let value):
                    return value

                case .physicalMemoryRatio(let ratio):
                    return .init(clamp(ratio, 0.0 as Double, 1.0 as Double) * Double(ProcessInfo.processInfo.physicalMemory))
                }
            }

        }

    }



    // MARK: .Request

    public struct Request {

        public typealias HttpHeader = (name: String, value: String)


        /// Path to requested resource.
        public var path: KvUrlPath.Slice

        /// Iterator of HTTP headers.
        public var headerIterator: AnyIterator<HttpHeader>?


        /// A member-wise initializer.
        @inlinable
        public init(path: KvUrlPath.Slice, headerIterator: AnyIterator<HttpHeader>? = nil) {
            self.path = path
            self.headerIterator = headerIterator
        }


        // MARK: Modifiers

        @usableFromInline
        consuming func modified(transform: (inout Request) -> Void) -> Request {
            var copy = self
            transform(&copy)
            return copy
        }


        /// This modifier assigns given iterator of HTTP headers to the receiver.
        @inlinable
        public consuming func headerIterator<H>(_ headerIterator: H) -> Request
        where H : IteratorProtocol, H.Element == HttpHeader
        { modified {
            $0.headerIterator = .init(headerIterator)
        } }

    }



    // MARK: .Representation

    /// Representation of a resource in a bundle.
    public struct Representation : Hashable {

        /// Language tag ([RFC 5646](https://datatracker.ietf.org/doc/html/rfc5646 )) to be used to select localized resources.
        public var languageTag: String?

    }



    // MARK: .ProcessedRequest

    struct ProcessedRequest : Hashable {

        let path: KvUrlPath.Slice
        let representation: Representation

    }



    // MARK: Operations

    /// - Returns: A representation from HTTP request headers.
    public func representation<H>(fromHttpHeaders headerIterator: H? = Optional<[Request.HttpHeader]>.none) -> Representation
    where H : Sequence, H.Element == Request.HttpHeader
    {
        var representation = Representation()

        // TODO: Refactoring to a cycle is required if two or more headers are be handled.

        do {
            let languageTags = headerIterator?
                .first(where: { $0.name.caseInsensitiveCompare("Accept-Language") == .orderedSame })?
                .value

            if let languageTags {
                representation.languageTag = localization.selectLanguageTag(forAcceptLanguageHeader: languageTags)
            }
        }

        return representation
    }


    /// - Returns: An HTTP response with contents of a resource matching given *request*.
    ///
    /// - SeeAlso: ``representation(fromHttpHeaders:)``.
    public func response(for request: borrowing Request) -> KvHttpResponseContent? {
        response(at: request.path, as: self.representation(fromHttpHeaders: request.headerIterator))
    }


    /// - Returns: An HTTP response with contents of a resource at given *path* in the bundle.
    ///
    /// - Note: `representation` is a closure to avoid it's evaluation when there is no need in it.
    public func response(at path: borrowing KvUrlPath.Slice,
                         as representation: @autoclosure () -> Representation
    ) -> KvHttpResponseContent? {
        assets[path]
        ?? navigationResponse(for: .init(path: path, representation: representation()))
    }


    private func navigationResponse(for request: ProcessedRequest) -> KvHttpResponseContent? {
        responseCache?[request, default: { responseBlock(request) }] ?? responseBlock(request)
    }

}



// MARK: - Legacy

// TODO: Delete in 1.0.0
@available(*, deprecated, renamed: "KvHttpBundle")
public typealias KvHtmlBundle = KvHttpBundle
