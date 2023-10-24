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
//  KvAxis.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 28.11.2023.
//

public typealias Axis = KvAxis



// TODO: DOC
public enum KvAxis : Int8, Hashable, CaseIterable, CustomStringConvertible {

    /// Horizontal dimension.
    case horizontal

    /// Vertical dimension.
    case vertical



    // MARK: .Set

    // TODO: DOC
    public struct Set : OptionSet {

        public static let horizontal = Self(rawValue: 1 << 0)

        public static let vertical = Self(rawValue: 1 << 1)


        // MARK: : OptionSet

        public let rawValue: Int8

        @inlinable public init(rawValue: Int8) { self.rawValue = rawValue }

    }



    // MARK: : CustomStringConvertible

    @inlinable
    public var description: String {
        switch self {
        case .horizontal: "horizontal"
        case .vertical: "vertical"
        }
    }

}
