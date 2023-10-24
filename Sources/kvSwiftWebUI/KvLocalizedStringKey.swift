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
//  KvLocalizedStringKey.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.10.2023.
//

public typealias LocalizedStringKey = KvLocalizedStringKey



// TODO: DOC
// TODO: Ensure initialization via StringInterpolation works
public struct KvLocalizedStringKey : Equatable, ExpressibleByStringLiteral {

    @usableFromInline
    let content: String


    @inlinable
    public init(_ content: String) { self.content = content }



    // MARK: : ExpressibleByStringLiteral

    @inlinable
    public init(stringLiteral value: String) { self.content = value }



    // MARK: : Equatable

    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.content == rhs.content }

}
