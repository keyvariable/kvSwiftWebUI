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
//  KvCssEdgeInsets.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 16.11.2023.
//


/// Representation of insets for *padding* and *margin*.
public struct KvCssEdgeInsets {

    public typealias Length = KvCssLength



    public var top, trailing, bottom, leading: Length



    // TODO: DOC
    @inlinable
    public init() { self.init(top: 0.0, trailing: 0.0, bottom: 0.0, leading: 0.0) }


    // TODO: DOC
    @inlinable
    public init(top: Length, leading: Length, bottom: Length, trailing: Length) {
        self.init(top: top, trailing: trailing, bottom: bottom, leading: leading)
    }


    // TODO: DOC
    @inlinable
    public init(top: Length, trailing: Length, bottom: Length, leading: Length) {
        self.top = top
        self.trailing = trailing
        self.bottom = bottom
        self.leading = leading
    }


    // TODO: DOC
    @inlinable
    public init(_ inset: Length) {
        self.init(top: inset, trailing: inset, bottom: inset, leading: inset)
    }


    // TODO: DOC
    @inlinable
    public init(top: Length, horizontal: Length, bottom: Length) {
        self.init(top: top, trailing: horizontal, bottom: bottom, leading: horizontal)
    }


    // TODO: DOC
    @inlinable
    public init(vertical: Length, horizontal: Length) {
        self.init(top: vertical, trailing: horizontal, bottom: vertical, leading: horizontal)
    }


    // TODO: DOC
    @inlinable
    public init(_ edges: Edge.Set, _ inset: Length) { self.init(
        top: edges.contains(.top) ? inset : 0.0,
        trailing: edges.contains(.trailing) ? inset : 0.0,
        bottom: edges.contains(.bottom) ? inset : 0.0,
        leading: edges.contains(.leading) ? inset : 0.0
    ) }



    // MARK: Fabrics

    /// Auxiliary fabric to combine optional insets.
    @inlinable
    public static func sum(_ lhs: Self?, _ rhs: Self?) -> Self? {
        guard let lhs = lhs else { return rhs }
        return lhs + rhs
    }



    // MARK: .Edge

    // TODO: DOC
    public enum Edge : Hashable, CaseIterable {

        case top
        case bottom
        case leading
        case trailing



        // MARK: .Set

        // TODO: DOC
        public struct Set : OptionSet, Equatable {

            public static let all: Self = [ top, bottom, leading, trailing ]

            public static let top = Self(rawValue: 1 << 0)
            public static let bottom = Self(rawValue: 1 << 1)
            public static let leading = Self(rawValue: 1 << 2)
            public static let trailing = Self(rawValue: 1 << 3)

            public static let horizontal: Self = [ leading, trailing ]
            public static let vertical: Self = [ top, bottom ]


            // MARK: : OptionSet

            public let rawValue: UInt

            @inlinable public init(rawValue: UInt) { self.rawValue = rawValue }

        }

    }



    // MARK: Operations

    /// - Returns: String with CSS representation of the receiver.
    @inlinable
    public var css: String { KvQuadruple(top.css, trailing.css, bottom.css, leading.css).css }



    // MARK: Operators

    @inlinable
    public static func +(lhs: Self, rhs: Self) -> Self { .init(
        top: lhs.top + rhs.top,
        trailing: lhs.trailing + rhs.trailing,
        bottom: lhs.bottom + rhs.bottom,
        leading: lhs.leading + rhs.leading
    ) }


    @inlinable
    public static func +(_ lhs: Self, _ rhs: Self?) -> Self {
        guard let rhs = rhs else { return lhs }
        return lhs + rhs
    }


    @inlinable
    public static func +(_ lhs: Self?, _ rhs: Self) -> Self {
        guard let lhs = lhs else { return rhs }
        return lhs + rhs
    }

}
