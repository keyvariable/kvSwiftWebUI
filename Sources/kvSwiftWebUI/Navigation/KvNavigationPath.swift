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
//  KvNavigationPath.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 11.01.2024.
//

import kvHttpKit



public typealias NavigationPath = KvNavigationPath



// TODO: DOC
public struct KvNavigationPath {

    static let empty = KvNavigationPath()



    // TODO: DOC
    // TODO: DOC: Note that first element corresponds to the root view.
    public private(set) var elements: [Element]



    @usableFromInline
    init(elements: [Element] = [ ]) {
        self.elements = elements
    }



    // MARK: .Element

    /// Type-erased element of navigation path.
    public struct Element {

        let value: Value
        /// Title of view for the element if available.
        public let title: KvText?

        /// Data the view has been generated for. It's `nil` for the root view.
        public var data: Any? {
            switch value {
            case .component(_, let data): data
            case .root: nil
            }
        }


        @usableFromInline
        init(value: Value, title: KvText?) {
            self.value = value
            self.title = title
        }


        @inlinable
        public init<D>(_ data: D) where D : LosslessStringConvertible {
            self.init(value: .component(data), title: nil)
        }


        @inlinable
        public init<D>(_ data: D) where D : RawRepresentable, D.RawValue : LosslessStringConvertible {
            self.init(value: .component(data), title: nil)
        }


        // MARK: .Value

        @usableFromInline
        enum Value {

            case root
            /// - Parameter data: Value  from `rawValue`.
            case component(rawValue: String, data: Any)


            // MARK: Fabrics

            @usableFromInline
            static func component<D>(_ data: D) -> Value where D : LosslessStringConvertible {
                .component(rawValue: data.description, data: data)
            }


            @usableFromInline
            static func component<D>(_ data: D) -> Value where D : RawRepresentable, D.RawValue : LosslessStringConvertible {
                .component(data.rawValue)
            }


            // MARK: Operations

            var urlPathComponent: String? {
                switch self {
                case .component(let rawValue, _): rawValue
                case .root: nil
                }
            }

        }

    }



    // MARK: Operations

    // TODO: DOC
    public var isEmpty: Bool { elements.isEmpty }

    // TODO: DOC
    public var count: Int { elements.count }


    var urlPath: KvUrlPath {
        .init(with: elements.lazy.compactMap { $0.value.urlPathComponent })
    }


    // TODO: DOC
    mutating public func append(_ element: Element) { elements.append(element) }


    // TODO: DOC
    @inlinable
    mutating public func append<D>(_ value: D) where D : LosslessStringConvertible {
        append(.init(value))
    }


    // TODO: DOC
    @inlinable
    mutating public func append<D>(_ value: D) where D : RawRepresentable, D.RawValue : LosslessStringConvertible {
        append(.init(value))
    }


    // TODO: DOC
    mutating public func removeLast(_ count: Int = 1) {
        elements.removeLast(count)
    }

}
