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
//  KvNavigationViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

// MARK: Auxiliaries

extension KvView {

    /// - Parameter transform: Argument is always non-nil.
    @inline(__always)
    @usableFromInline
    consuming func withModifiedNavigation(_ transform: (inout KvViewConfiguration.Navigation?) -> Void) -> some KvView {
        modified { configuration in
            if configuration.navigation == nil {
                configuration.navigation = .init()
            }
            transform(&configuration.navigation)
            return nil
        }
    }

}



// MARK: Navigation Modifiers

extension KvView {

    // TODO: stringgen function
    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ titleKey: KvLocalizedStringKey) -> some KvView { withModifiedNavigation {
        // TODO: I18n
        $0!.title = KvText(titleKey)
    } }


    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ title: String) -> some KvView { withModifiedNavigation {
        $0!.title = KvText(verbatim: title)
    } }


    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ title: KvText) -> some KvView { withModifiedNavigation {
        $0!.title = title
    } }

}
