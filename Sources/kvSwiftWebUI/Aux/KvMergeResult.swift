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
//  KvMergeResult.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 11.11.2023.
//

// TODO: DOC
enum KvMergeResult<T> {

    case merged(T)
    case incompatibility



    // MARK: Operations

    consuming func map<R>(_ transform: (T) throws -> R) rethrows -> KvMergeResult<R> {
        switch self {
        case .merged(let value): try .merged(transform(value))
        case .incompatibility: .incompatibility
        }
    }

}
