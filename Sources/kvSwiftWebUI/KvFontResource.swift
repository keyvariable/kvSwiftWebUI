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
//  KvFontResource.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 08.12.2023.
//

import Foundation

import kvHttpKit



public typealias FontResource = KvFontResource



// TODO: DOC
public struct KvFontResource : Hashable {

    var name: String

    /// Faces decomposed on keys and sources. Sources are sorted.
    var faces: [Face.Key : [Source]]



    public init(name: String, faces: [Face]) {
        self.name = name
        // First sources of faces for the same keys are united. Then sources are sorted to preserve caches.
        self.faces = [Face.Key : Set<Source>](faces.lazy.map { face in (key: Face.Key(for: face), value: face.sources) }) { $0.union($1) }
            .mapValues { $0.sorted() }

    }



    // MARK: .Face

    public struct Face : Hashable {

        public var sources: Set<Source>

        public var weight: KvFont.Weight
        public var isItalic: Bool


        public init(sources: Set<Source>, weight: KvFont.Weight = .regular, isItalic: Bool = false) {
            self.sources = sources
            self.weight = weight
            self.isItalic = isItalic
        }


        // MARK: .Key

        struct Key : Hashable {

            let weight: KvFont.Weight
            let isItalic: Bool


            init(weight: KvFont.Weight, isItalic: Bool) {
                self.weight = weight
                self.isItalic = isItalic
            }


            init(for face: Face) { self.init(weight: face.weight, isItalic: face.isItalic) }

        }

    }



    // MARK: .Source

    public enum Source : Hashable, Comparable {

        case local(name: String)
        /// A resource in a bundle.
        case resource(String?, extension: String? = nil, bundle: Bundle? = nil, subdirectory: String? = nil, format: Format? = nil)
        case url(URL, Format? = nil)


        // MARK: Fabrics

        @available(*, deprecated, renamed: "resource(_:extension:bundle:subdirectory:format:)")
        public static func url(resource: String,
                               withExtension extension: String? = nil,
                               subdirectory: String? = nil,
                               bundle: Bundle? = nil,
                               format: Format? = nil
        ) -> Self? {
            .resource(resource, extension: `extension`, bundle: bundle, subdirectory: subdirectory, format: format)
        }


        // MARK: .Format

        public enum Format : Hashable {

            case collection
            case embeddedOpenType
            case openType
            case svg
            case trueType
            case woff
            case woff2


            init?(_ contentType: KvHttpContentType) {
                switch contentType {
                case .font(.collection):
                    self = .collection
                case .font(.otf):
                    self = .openType
                case .font(.ttf):
                    self = .trueType
                case .font(.woff):
                    self = .woff
                case .font(.woff2):
                    self = .woff2
                default:
                    return nil
                }
            }


            var contentType: KvHttpContentType? {
                switch self {
                case .collection: .font(.collection)
                case .embeddedOpenType: nil
                case .openType: .font(.otf)
                case .svg: nil
                case .trueType: .font(.ttf)
                case .woff: .font(.woff)
                case .woff2: .font(.woff2)
                }
            }


            // MARK: CSS

            var css: String {
                let value: String = switch self {
                case .collection: "collection"
                case .embeddedOpenType: "embeddedOpenType"
                case .openType: "openType"
                case .svg: "svg"
                case .trueType: "trueType"
                case .woff: "woff"
                case .woff2: "woff2"
                }

                return "format(\(value))"
            }

        }


        // MARK: : Equatable

        public static func ==(lhs: Self, rhs: Self) -> Bool {
            switch lhs {
            case .local(name: let lhs):
                guard case .local(lhs) = rhs else { return false }

            case let .resource(resource, extension: `extension`, bundle: bundle, subdirectory: subdirectory, format: format):
                guard case .resource(resource, `extension`, bundle, subdirectory, format) = rhs else { return false }

            case .url(let url, _):
                guard case .url(url, _) = rhs else { return false }
            }

            return true
        }


        // MARK: : Hashable

        public func hash(into hasher: inout Hasher) {
            switch self {
            case .local(let name):
                hasher.combine(name)

            case let .resource(resource, extension: `extension`, bundle: bundle, subdirectory: subdirectory, format: _):
                hasher.combine(resource)
                hasher.combine(`extension`)
                hasher.combine(bundle)
                hasher.combine(subdirectory)

            case .url(let url, _):
                hasher.combine(url)
            }
        }


        // MARK: : Comparable

        public static func <(lhs: Self, rhs: Self) -> Bool {

            enum Kind : UInt, Comparable {

                case local, resource, url

                init(_ source: Source) {
                    switch source {
                    case .local(_):
                        self = .local
                    case .resource(_, extension: _, bundle: _, subdirectory: _, format: _):
                        self = .resource
                    case .url(_, _):
                        self = .url
                    }
                }

                // MARK: : Comparable

                static func <(lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

            }


            /// Auxiliary compare function providing ability to cascade comparisons.
            /// It returns `nil` when *lhs* is equal to *rhs*.
            func Is<T : Comparable>(_ lhs: T, lessThen rhs: T) -> Bool? {
                if lhs < rhs { return true }
                else if rhs < lhs { return false }
                else { return nil }
            }


            /// Auxiliary compare function providing ability to cascade comparisons.
            /// It returns `nil` when *lhs* is equal to *rhs*.
            ///
            /// - Note: `.none` &lt; `.some(_)`
            func Is<T : Comparable>(_ lhs: T?, lessThen rhs: T?) -> Bool? {
                switch (lhs, rhs) {
                case (.none, .none), (.some, .none): false
                case (.none, .some): true
                case (.some(let lhs), .some(let rhs)): Is(lhs, lessThen: rhs)
                }
            }


            switch lhs {
            case .local(name: let lhs):
                guard case .local(let rhs) = rhs else { break }
                return lhs < rhs

            case let .resource(lResource, extension: lExtension, bundle: lBundle, subdirectory: lSubdirectory, format: _):
                guard case let .resource(rResource, extension: rExtension, bundle: rBundle, subdirectory: rSubdirectory, format: _) = rhs else { break }
                return (Is(lResource, lessThen: rResource)
                        ?? Is(lExtension, lessThen: rExtension)
                        ?? Is(lBundle?.bundleURL.absoluteString, lessThen: rBundle?.bundleURL.absoluteString)
                        ?? Is(lSubdirectory, lessThen: rSubdirectory)
                        ?? false)

            case .url(let lhs, _):
                guard case .url(let rhs, _) = rhs else { break }
                return lhs.absoluteString < rhs.absoluteString
            }

            // It's evaluated when lhs and rhs are differenct enum cases.
            return Kind(lhs) < Kind(rhs)
        }

    }

}
