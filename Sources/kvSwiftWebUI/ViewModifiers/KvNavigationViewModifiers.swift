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

// MARK: Navigation Modifiers

extension KvView {

    // TODO: stringgen function
    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ titleKey: KvLocalizedStringKey) -> some KvView { mapConfiguration {
        // TODO: I18n
        $0!.navigationTitle = KvText(titleKey)
    } }


    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ title: String) -> some KvView { mapConfiguration {
        $0!.navigationTitle = KvText(verbatim: title)
    } }


    // TODO: DOC
    @inlinable
    public consuming func navigationTitle(_ title: KvText) -> some KvView { mapConfiguration {
        $0!.navigationTitle = title
    } }


    
    @usableFromInline
    consuming func navigationDestination<C : KvView>(destination: @escaping (String) -> C?) -> some KvView {
        mapConfiguration {
            $0!.appendNavigationDestinations(destination)
        }
    }


    // TODO: DOC
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : LosslessStringConvertible, Content : KvView
    {
        navigationDestination { D($0).map(destination) }
    }


    // TODO: DOC
    public consuming func navigationDestination<D, Content>(for data: D.Type, @KvViewBuilder destination: @escaping (D) -> Content) -> some KvView
    where D : RawRepresentable, D.RawValue : LosslessStringConvertible, Content : KvView
    {
        navigationDestination { D.RawValue($0).flatMap(D.init(rawValue:)).map(destination) }
    }

}
