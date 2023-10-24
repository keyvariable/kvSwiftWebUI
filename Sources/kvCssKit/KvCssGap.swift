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
//  KvCssGap.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 26.11.2023.
//

/// Representation of CSS [gap shorthand](https://www.w3.org/TR/2023/WD-css-align-3-20230217/#gap-shorthand ).
public struct KvCssGap : Equatable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {

    public var row, column: KvCssLength



    @inlinable
    public init(_ row: KvCssLength, _ column: KvCssLength) {
        self.row = row
        self.column = column
    }


    @inlinable
    public init(_ value: KvCssLength) { self.init(value, value) }



    // MARK: : ExpressibleByFloatLiteral

    @inlinable
    public init(floatLiteral value: FloatLiteralType) { self.init(.init(floatLiteral: value)) }



    // MARK: : ExpressibleByIntegerLiteral

    @inlinable
    public init(integerLiteral value: IntegerLiteralType) { self.init(.init(integerLiteral: value)) }



    // MARK: Operations

    @inlinable
    public var css: String { KvCouple(row.css, column.css).css }

}
