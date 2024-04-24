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

import kvHttpKit

import Foundation



/// *KvHttpBundle* resolves the root view to collection HTTP responses including HTML, styles, resources, etc.
///
/// When bundle is initialized, use ``response(for:)`` methods to process requests and get responses.
///
/// Use ``Configuration`` structure and ``init(with:rootView:)`` initializer to customize bundle.
/// By default maximum size of response cache is 50% of physical memory on the machine.
///
/// HTTP bundles support localization.
/// Localization is evaluated explicitly from URL or can be inferred from Accept-Language HTTP header.
/// Explicit list of the language tags ([RFC 5646](https://datatracker.ietf.org/doc/html/rfc5646 ))
/// can be provided via ``Constants/languageTagsUrlQueryItemName`` ("lang") URL query item.
/// For example, use "https://example.com?lang=zh-Hant" to request traditional Chinese localization of *example.com*.
///
/// HTTP bundles support automatic generation of sitemaps.
/// Sitemaps are generated from static navigation destinations, see ``KvView/navigationDestination(for:destination:)-9x6uf`` for details.
/// Dynamic navigation destinations are currently ignored.
/// Generation of sitemaps is configured via ``Configuration/sitemap-swift.property``.
///
/// When the responses are served with [kvServerKit](https://github.com/keyvariable/kvServerKit.swift.git ),
/// bundles can be used as root response group expressions:
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
        icon: KvApplicationIcon? = nil,
        @KvViewBuilder rootView: @escaping () -> RootView
    ) throws
    where RootView : KvView
    {
        try self.init(with: .init(icon: icon), rootView: rootView)
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
            with: .init(iconHeaders: configuration.icon?.htmlHeaders,
                        assets: assets,
                        localization: localization,
                        defaultBundle: configuration.defaultBundle,
                        authorsTag: configuration.authorsTag)
        )

        sitemap = configuration.sitemap.map(Sitemap.init(from:))
    }



    private typealias ResponseBlock = (borrowing ProcessedRequest) -> KvHttpResponseContent?


    private let assets = KvHttpBundleAssets()
    private let localization: KvLocalization

    private let navigationController: KvNavigationController

    private let responseCache: KvHttpResponseCache<ProcessedRequest>?

    private let sitemap: Sitemap?



    // MARK: .Constants

    public struct Constants {

        /// Name of URL query item with language tags to use instead of value of `Accept-Language` header.
        /// This query item is used to force use of a language, e.g. for the search robots in the sitemap.
        public static let languageTagsUrlQueryItemName = "lang"

    }



    // MARK: .Sitemap

    /// Prepared configuration of sitemap.
    private struct Sitemap {

        let format: KvSitemap.Format

        /// - Note: It's of `Substring` type for internal needs.
        let pathComponent: Substring


        init(from configuration: borrowing Configuration.Sitemap) {
            format = configuration.format
            pathComponent = .init(configuration.pathComponent)
        }

    }



    // MARK: .Request

    public struct Request {

        public typealias HttpHeader = (name: String, value: String)



        /// Components of requests URL.
        public let urlComponents: URLComponents

        /// Structured path from ``urlComponents``.
        @usableFromInline
        let urlPath: KvUrlPath.Slice

        /// Iterator of HTTP headers.
        public var headerIterator: AnyIterator<HttpHeader>?


        /// A member-wise initializer.
        @inlinable
        package init(urlComponents: URLComponents,
                     urlPath: KvUrlPath.Slice,
                     headerIterator: AnyIterator<HttpHeader>? = nil
        ) {
            self.urlComponents = urlComponents
            self.urlPath = urlPath
            self.headerIterator = headerIterator
        }


        @inlinable
        public init(urlComponents: URLComponents,
                    headerIterator: AnyIterator<HttpHeader>? = nil
        ) {
            self.init(urlComponents: urlComponents,
                      urlPath: .init(path: urlComponents.path),
                      headerIterator: headerIterator)
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



    // MARK: .RepresentationContext

    /// ``Representation`` and some related attributes.
    fileprivate struct RepresentationContext {

        let representation: Representation

        let urlQuery: ProcessedRequest.UrlQuery

        let languageTagSource: LanguageTagSource


        // MARK: .LanguageTagSource

        enum LanguageTagSource {
            /// Explicitly provided language tag. E.g. it can be provided via URL query.
            case explicit
            /// Implicitly evaluated language tag. E.g. via Accept-Language HTTP header.
            case inferred
        }

    }



    // MARK: .ProcessedRequest

    // TODO: Store URL query in ProcessedRequest, remove `: Hashable`, refactor the response cache to store to use path and representation as first key, the normalized query as second key.
    struct ProcessedRequest : Hashable {

        /// - Note: Assuming URL query doesn't contain items with duplicated names.
        typealias UrlQuery = [String : String?]


        fileprivate let urlComponents: URLComponents

        /// Structured path from ``urlComponents``.
        let urlPath: KvUrlPath.Slice
        /// URL query items from ``urlComponents`` in `Dictionary` container.
        let urlQuery: UrlQuery

        let representation: Representation


        fileprivate init(request: borrowing Request, context: borrowing RepresentationContext) {
            var urlComponents = request.urlComponents

            // TODO: Don't clear .queryItems when the cache will use some other key instead of ProcessedRequest.
            urlComponents.queryItems = nil

            self.urlComponents = urlComponents
            urlPath = request.urlPath
            urlQuery = context.urlQuery
            representation = context.representation
        }


        // MARK: Auxiliaries

        var bundleUrlComponents: URLComponents {
            var urlComponents = self.urlComponents

            urlComponents.path = ""
            urlComponents.queryItems = nil
            urlComponents.fragment = nil

            return urlComponents
        }


        func urlComponents(transform: (inout URLComponents) -> Void = { _ in }) -> URLComponents {
            var urlComponents = self.urlComponents

            transform(&urlComponents)

            KvUrlKit.normalizeUrlQueryItems(in: &urlComponents)

            return urlComponents
        }

    }



    // MARK: Operations

    /// - Returns: A representation from URL and HTTP request headers.
    ///
    /// - Note: Localization is evaluated from URL query item named ``Constants/languageTagsUrlQueryItemName`` ("lang") and HTTP headers.
    public func representation<H>(
        urlQuery: borrowing [URLQueryItem] = [ ],
        httpHeaders headerIterator: H? = Optional<[Request.HttpHeader]>.none
    ) -> Representation
    where H : Sequence, H.Element == Request.HttpHeader
    {
        representationContext(urlQuery: urlQuery, httpHeaders: headerIterator)
            .representation
    }


    /// - Returns: A representation context from HTTP request headers.
    private func representationContext<H>(
        urlQuery: [URLQueryItem],
        httpHeaders headerIterator: H?
    ) -> RepresentationContext
    where H : Sequence, H.Element == Request.HttpHeader
    {
        var representation = Representation()
        var languageTagSource: RepresentationContext.LanguageTagSource

        let urlQuery = Dictionary(urlQuery.lazy.map { ($0.name, $0.value) }, uniquingKeysWith: { lhs, rhs in lhs })

        (representation.languageTag, languageTagSource) = switch explicitLanguageTag(from: urlQuery) {
        case .some(let value):
            (value, .explicit)
        case .none:
            (inferredLanguageTag(from: headerIterator), .inferred)
        }

        return .init(
            representation: representation,
            urlQuery: urlQuery,
            languageTagSource: languageTagSource
        )
    }


    private func explicitLanguageTag(from urlQuery: borrowing ProcessedRequest.UrlQuery) -> String? {
        guard let languageTags = urlQuery.first(where: { $0.key == Constants.languageTagsUrlQueryItemName })?.value
        else { return nil }

        return localization.selectLanguageTag(forAcceptLanguageHeader: languageTags)
    }


    private func inferredLanguageTag<H>(from headerIterator: H?) -> String?
    where H : Sequence, H.Element == Request.HttpHeader
    {
        guard let languageTags = headerIterator?
            .first(where: { $0.name.caseInsensitiveCompare("Accept-Language") == .orderedSame })?
            .value
        else { return nil }

        return (localization.selectLanguageTag(forAcceptLanguageHeader: languageTags)
                ?? localization.defaultLanguageTag)
    }


    /// - Returns: An HTTP response with contents of a resource matching given *request*.
    ///
    /// - SeeAlso: ``representation(urlQuery:httpHeaders:)``.
    public func response(for request: borrowing Request) -> KvHttpResponseContent? {
        let representationContext = representationContext(urlQuery: request.urlComponents.queryItems ?? [ ],
                                                          httpHeaders: request.headerIterator)

        let processedRequest = ProcessedRequest(request: request, context: representationContext)

        // If localization is explicit and implicit localization is available then it's omitted via redirect.
        //
        // Assuming the robots don't provide Accept-Language so implicit localization is not available for them.
        if case .explicit = representationContext.languageTagSource,
           let explicitLanguageTag = representationContext.representation.languageTag,
           let inferredLanguageTag = inferredLanguageTag(from: request.headerIterator),
           consume inferredLanguageTag == consume explicitLanguageTag,
           let response = noLanguageTagResponse(for: processedRequest)
        {
            return response
        }

        return response(for: processedRequest)
    }


    private func response(for request: borrowing ProcessedRequest) -> KvHttpResponseContent? {
        if let response = assets[request.urlPath] {
            return response
        }

        let responseBlock: ResponseBlock = {
            if request.urlPath.components.count == 1 {
                switch request.urlPath.components.last {
                case sitemap?.pathComponent:
                    let sitemapFormat = sitemap!.format

                    return { request in
                        self.sitemapResponse(representation: request.representation,
                                             bundleUrlComponents: request.bundleUrlComponents,
                                             format: sitemapFormat)
                    }

                default:
                    break
                }
            }

            return self.navigationResponse(for:)
        }()

        return cachedResponse(for: request, responseProvider: responseBlock)
    }


    private func cachedResponse(for request: ProcessedRequest,
                                responseProvider: (borrowing ProcessedRequest) -> KvHttpResponseContent?
    ) -> KvHttpResponseContent? {
        responseCache?[request, default: { responseProvider(request) }] ?? responseProvider(request)
    }


    private func navigationResponse(for request: borrowing ProcessedRequest) -> KvHttpResponseContent? {
        let urlComponents = request.urlComponents

        return navigationController.htmlResponse(for: request)?
            .headers {
                $0("Link", self.localizationHeader(with: urlComponents))
            }
    }


    private func sitemapResponse(representation: borrowing Representation,
                                 bundleUrlComponents: URLComponents,
                                 format: KvSitemap.Format
    ) -> KvHttpResponseContent? {
        var urlComponents = bundleUrlComponents

        if let languageTag = representation.languageTag {
            KvUrlKit.append(&urlComponents,
                            withUrlQueryItem: .init(name: Constants.languageTagsUrlQueryItemName, value: languageTag))
        }

        assert(urlComponents.path.isEmpty)

        switch format {
        case .plainText:
            var encoder = KvSitemap.TextEncoder()

            navigationController.enumeratePaths(representation: representation) { path, stopFlag in
                urlComponents.path = path

                guard let url = urlComponents.url else { return }

                switch encoder.append(url) {
                case .failure(.totalByteLimitExceeded):
                    stopFlag = true
                case .success, .failure(.unableToEncodeURL(_)):
                    break
                }
            }

            return encoder.response()
        }
    }


    /// - Returns: Redirection response to url having to explicit language tags.
    private func noLanguageTagResponse(for request: borrowing ProcessedRequest) -> KvHttpResponseContent? {
        let urlComponents = request.urlComponents {
            $0.queryItems?.removeAll(where: { $0.name == Constants.languageTagsUrlQueryItemName })
        }

        guard let url = (consume urlComponents).url else { return nil }

        return .seeOther(location: url)
    }


    private func localizationHeader(with urlComponents: URLComponents) -> String {
        var urlComponents = urlComponents

        KvUrlKit.append(&urlComponents, withUrlQueryItem: .init(name: Constants.languageTagsUrlQueryItemName, value: nil))

        let queryItemIndex = urlComponents.queryItems!.endIndex - 1

        return localization.languageTags
            .lazy.compactMap { languageTag -> String? in
                urlComponents.queryItems![queryItemIndex].value = languageTag

                guard let url = urlComponents.url else { return nil }

                return "\(url.absoluteString);rel=\"alternate\";hreflang=\"\(languageTag)\""
            }
            .joined(separator: ",")
    }

}



// MARK: - Legacy

// TODO: Delete in 1.0.0
@available(*, deprecated, renamed: "KvHttpBundle")
public typealias KvHtmlBundle = KvHttpBundle


extension KvHttpBundle {

    @available(*, unavailable, message: "Use `response(for:)` instead")
    public func response(at path: KvUrlPath.Slice,
                         as representation: @autoclosure () -> Representation
    ) -> KvHttpResponseContent? {
        nil
    }

}
