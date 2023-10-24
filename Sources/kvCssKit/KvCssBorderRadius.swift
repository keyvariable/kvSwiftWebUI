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
//  KvCssBorderRadius.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

/// Representation of radii values for border-radius CSS property.
public struct KvCssBorderRadius : Equatable, ExpressibleByFloatLiteral {

    public var topLeft, topRight, bottomRight, bottomLeft: CornerRadii



    @inlinable
    public init(topLeft: CornerRadii, topRight: CornerRadii, bottomRight: CornerRadii, bottomLeft: CornerRadii) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
    }


    @inlinable
    public init(_ radius: KvCssLength) {
        self.init(CornerRadii(radius))
    }


    @inlinable
    public init(_ radii: CornerRadii) {
        self.init(topLeft: radii, topRight: radii, bottomRight: radii, bottomLeft: radii)
    }


    @inlinable
    public init(topLeft: KvCssLength, topRight: KvCssLength, bottomRight: KvCssLength, bottomLeft: KvCssLength) {
        self.topLeft = .init(topLeft)
        self.topRight = .init(topRight)
        self.bottomRight = .init(bottomRight)
        self.bottomLeft = .init(bottomLeft)
    }



    // MARK: .CornerRadii

    public struct CornerRadii : Equatable {

        public var x, y: KvCssLength


        @inlinable
        public init(x: KvCssLength, y: KvCssLength) {
            self.x = x
            self.y = y
        }


        @inlinable
        public init(_ radius: KvCssLength) { self.init(x: radius, y: radius) }


        // MARK: Aliases

        @inlinable
        public var first: KvCssLength {
            get { x }
            set { x = newValue }
        }

        @inlinable
        public var second: KvCssLength {
            get { y }
            set { y = newValue }
        }

    }



    // MARK: : ExpressibleByFloatLiteral

    @inlinable
    public init(floatLiteral value: FloatLiteralType) {
        self.init(KvCssLength(value))
    }



    // MARK: Operations

    /// - Returns: String with CSS representation of the receiver.
    @inlinable
    public var css: String {
        let first = KvQuadruple(topLeft.first.css, topRight.first.css, bottomRight.first.css, bottomLeft.first.css)
        let second = KvQuadruple(topLeft.second.css, topRight.second.css, bottomRight.second.css, bottomLeft.second.css)

        return first != second ? "\(first.css)/\(second.css)" : first.css
    }

}
