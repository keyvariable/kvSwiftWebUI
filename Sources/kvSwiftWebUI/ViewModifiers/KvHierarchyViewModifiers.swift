//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  KvHierarchyViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 03.02.2024.
//

// MARK: View Hierarchy Modifiers

extension KvView {

    /// This modifier associates given *tag* value with the receiver. It's assumed that views have unique tags.
    ///
    /// Tag is passed as `id` HTML attribute, when:
    /// - `tag` is a `String`;
    /// - `tag` conforms to `LosslessStringConvertible` protocol;
    /// - `tag` conforms to `RawRepresentable` and the `RawValue` is `String` or `LosslessStringConvertible`.
    @inlinable
    public consuming func tag<T>(_ tag: T) -> some View
    where T : Hashable
    {
        mapConfiguration { $0!.tag = tag }
    }

}
