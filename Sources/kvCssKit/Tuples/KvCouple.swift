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
//  KvCouple.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

@usableFromInline
struct KvCouple : Equatable {

    var v0, v1: String


    @usableFromInline
    init(_ v0: String, _ v1: String) {
        self.v0 = v0
        self.v1 = v1
    }


    // MARK: Operations

    @usableFromInline
    var css: String {
        guard v0 == v1 else { return "\(v0) \(v1)" }
        return v0
    }

}
