//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  KvHttpBundleConfiguration.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 09.04.2024.
//

import Foundation

import kvHttpKit
import kvKit



// MARK: .Configuration

extension KvHttpBundle {

    public struct Configuration {

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

        /// Configuration of the sitemap. If it's `nil` then the sitemap is not generated.
        ///
        /// Default value is ``Sitemap/default``.
        public var sitemap: Sitemap?

        /// A text to be used as the author's tag.
        public var authorsTag: KvText?



        /// - Parameters:
        ///   - icon: Initial value for ``icon`` property.
        ///   - responseCacheSize: Initial value for ``responseCacheSize`` property.
        ///   - defaultBundle: Initial value for ``defaultBundle`` property.
        ///   - sitemap: Initial value for ``sitemap`` property.
        ///   - authorsTag: Initial value for ``authorsTag`` property.
        @inlinable
        public init(icon: KvApplicationIcon? = nil,
                    responseCacheSize: ResponseCacheSize? = .physicalMemoryRatio(0.5),
                    defaultBundle: Bundle? = nil,
                    sitemap: Sitemap? = .default,
                    authorsTag: KvText? = nil
        ) {
            self.icon = icon
            self.responseCacheSize = responseCacheSize
            self.defaultBundle = defaultBundle
            self.sitemap = sitemap
            self.authorsTag = authorsTag
        }

    }

}



// MARK: .ResponseCacheSize

extension KvHttpBundle.Configuration {

    public enum ResponseCacheSize : ExpressibleByIntegerLiteral {

        /// Number of bytes to be used as maximum size of the response cache.
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



// MARK: .Sitemap

extension KvHttpBundle.Configuration {

    /// Configuration of the sitemap.
    ///
    /// Sitemap is generated from the navigation tree for destinations those values are of types conforming to `CaseIterable` protocol.
    public struct Sitemap {

        public static let `default` = Sitemap()


        /// Name of the sitemap file excluding path extension. Default value is ``Defaults/fileName``.
        ///
        /// - SeeAlso: ``pathComponent``.
        public var fileName: String

        public var format: KvSitemap.Format


        @inlinable
        public init(fileName: String = Defaults.fileName, format: KvSitemap.Format = Defaults.format) {
            self.fileName = fileName
            self.format = format
        }


        // MARK: .Defaults

        public struct Defaults {

            public static let fileName: String = "sitemap"
            public static let format: KvSitemap.Format = .plainText

        }


        // MARK: Operations

        /// Path component including file name and path extension.
        @inlinable
        public var pathComponent: String { KvSitemap.pathComponent(fileName: fileName, format: format) }

    }

}
