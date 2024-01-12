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

    private(set) var elements: [Element]



    @usableFromInline
    init(elements: [Element] = [ ]) {
        self.elements = elements
    }



    // MARK: .Element

    /// Type-erased element of navigation path.
    public struct Element {

        let rawValue: String

        /// Value  from `.rawValue`.
        public let data: Any
        /// Title of view for the element if available.
        public let title: KvText?


        @usableFromInline
        init(rawValue: String, data: Any, title: KvText?) {
            self.rawValue = rawValue
            self.data = data
            self.title = title
        }


        @inlinable
        public init<D>(_ data: D) where D : LosslessStringConvertible {
            self.init(rawValue: data.description, data: data, title: nil)
        }


        @inlinable
        public init<D>(_ data: D) where D : RawRepresentable, D.RawValue : LosslessStringConvertible {
            self.init(data.rawValue)
        }

    }



    // MARK: Operations

    // TODO: DOC
    public var isEmpty: Bool { elements.isEmpty }

    // TODO: DOC
    public var count: Int { elements.count }


    var urlPath: KvUrlPath {
        .init(with: elements.lazy.map { $0.rawValue })
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
