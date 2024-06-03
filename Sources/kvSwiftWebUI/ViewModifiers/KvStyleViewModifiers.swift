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
//  KvStyleViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.05.2024.
//

// MARK: Style Modifiers

extension KvView {

    /// - SeeAlso: <doc:/documentation/kvSwiftWebUI/KvView/listStyle(_:)-76ph0>.
    @inlinable
    public consuming func listStyle(_ style: KvAnyListStyle) -> some KvView { mapConfiguration { configuration -> Void in
        configuration!.listStyle = style
    } }
    

    /// This modifier sets the style for lists within the receiver.
    @inlinable
    public consuming func listStyle<S>(_ style: S) -> some KvView
    where S : ListStyle
    {
        listStyle(style.eraseToAnyListStyle())
    }

}
