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
//  KvViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

// MARK: Auxiliaries

extension KvView {

    /// - Parameter transform: A block returning an optional configuration for a wrapper container to create. If `nil` then container is not created.
    @inline(__always)
    @usableFromInline
    consuming func modified(_ transform: (inout KvViewConfiguration) -> KvViewConfiguration?) -> some KvView {
        let view = consume self
        return ((view as? KvModifiedView) ?? KvModifiedView(source: { view })).modified(transform)
    }

}
