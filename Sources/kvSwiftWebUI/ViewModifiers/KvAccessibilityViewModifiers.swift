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
//  KvAccessibilityViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 12.05.2024.
//

import Foundation



// MARK: Contextual Help Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func help(_ text: KvText) -> some KvView { mapConfiguration {
        $0!.help = text
    } }


    /// An overload of ``help(_:)-68to3`` modifier.
    @inlinable
    public consuming func help(_ key: KvLocalizedStringKey) -> some KvView { help(KvText(key)) }


    /// An overload of ``help(_:)-68to3`` modifier.
    @_disfavoredOverload
    @inlinable
    public consuming func help<S>(_ string: S) -> some KvView
    where S : StringProtocol
    { help(KvText(string)) }

}
