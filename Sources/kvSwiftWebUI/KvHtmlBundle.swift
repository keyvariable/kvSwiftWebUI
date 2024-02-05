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

import kvHttpKit
import kvKit



/// *KvHtmlBundle* resolves the root view to collection HTTP responses including HTML, styles, resources, etc.
///
/// When bundle is initialized, the responses are fetched by URL paths using ``response(at:)`` method.
///
/// By default it's assumed that bundle is served to the domain's root path and maximum size of response cache is 50% of physical memory on the machine.
/// Use ``Configuration`` structure and ``init(with:rootView:)`` initializer to customize bundle.
public class KvHtmlBundle {

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
        configuration.icon?.forEachHtmlResource(assets.insert(_:))

        responseCache = configuration.responseCacheSize.map {
            .init(maximumByteSize: $0.value)
        }

        navigationController = .init(
            for: rootView(),
            with: .init(rootPath: configuration.rootPath,
                        iconHeaders: configuration.icon?.htmlHeaders,
                        assets: assets)
        )

        do {
            let navigationController = navigationController
            // - NOTE: Catching reference to `self` is avoided to prevent retain cycle.
            responseBlock = { navigationController.htmlResponse(at: $0) }
        }
    }



    private let assets = KvHtmlBundleAssets()

    private let navigationController: KvNavigationController

    private let responseCache: KvHttpResponseCache<KvUrlPath.Slice>?
    /// A block to be used to synthesize response when there is no cached value.
    private let responseBlock: (KvUrlPath.Slice) -> KvHttpResponseContent?



    // MARK: .Configuration

    public struct Configuration {

        /// A path on the server the root view is served at. Empty or `nil` values mean that the root view is served at "/" path.
        public var rootPath: KvUrlPath?

        /// An icon to be used in browser UI, on OS home screens, etc.
        public var icon: KvApplicationIcon?

        /// Maximum size of cached responses. If `nil` then the cache is disabled. By default cache uses 50% of physical memory on the machine.
        public var responseCacheSize: ResponseCacheSize?



        /// - Parameters:
        ///   - rootPath: See ``rootPath`` for details.
        ///   - icon: See ``icon`` for details.
        ///   - responseCacheSize: See ``responseCacheSize`` for details.
        @inlinable
        public init(rootPath: KvUrlPath? = nil,
                    icon: KvApplicationIcon? = nil,
                    responseCacheSize: ResponseCacheSize? = .physicalMemoryRatio(0.5)
        ) {
            self.rootPath = rootPath
            self.icon = icon
            self.responseCacheSize = responseCacheSize
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



    // MARK: Operations

    /// - Returns: An HTTP response with contents of resource at given *path* in the bundle.
    public func response(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        assets[path]
        ?? navigationResponse(at: path)
    }


    private func navigationResponse(at path: KvUrlPath.Slice) -> KvHttpResponseContent? {
        responseCache?[path, default: { responseBlock(path) }] ?? responseBlock(path)
    }

}
