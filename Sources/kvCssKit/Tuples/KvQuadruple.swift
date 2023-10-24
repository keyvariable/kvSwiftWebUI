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
//  KvQuadruple.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

/// Tuple of 4 CSS values. It provides as short CSS representation as possible.
@usableFromInline
struct KvQuadruple : Equatable {

    var v0, v1, v2, v3: String


    @usableFromInline
    init(_ v0: String, _ v1: String, _ v2: String, _ v3: String) {
        self.v0 = v0
        self.v1 = v1
        self.v2 = v2
        self.v3 = v3
    }


    // MARK: Operations

    @usableFromInline
    var css: String {
        guard v1 == v3 else { return "\(v0) \(v1) \(v2) \(v3)" }
        guard v0 == v2 else { return "\(v0) \(v1) \(v2)" }
        guard v0 == v1 else { return "\(v0) \(v1)" }
        return v0
    }

}
