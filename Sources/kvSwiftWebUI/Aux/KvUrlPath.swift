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
//  KvUrlPath.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 29.12.2023.
//

import kvHttpKit



extension KvUrlPath : Comparable {

    public static func <(lhs: Self, rhs: Self) -> Bool {
        var lhs = lhs.components.makeIterator()
        var rhs = rhs.components.makeIterator()

        while let lhs = lhs.next(),
              let rhs = rhs.next()
        {
            switch lhs.compare(rhs) {
            case .orderedAscending:
                return true
            case .orderedDescending:
                return false
            case .orderedSame:
                break
            }
        }

        return rhs.next() != nil
    }

}
