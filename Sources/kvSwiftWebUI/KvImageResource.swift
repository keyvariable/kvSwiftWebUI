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
//  KvImageResource.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.11.2023.
//

import Foundation



public typealias ImageResource = KvImageResource



// TODO: DOC
public struct KvImageResource : Hashable {

    @usableFromInline
    var selector: Selector

    @usableFromInline
    var bundle: Bundle


    @usableFromInline
    var name: String {
        get { selector.name }
        set { selector.name = newValue }
    }



    @inlinable
    public init(name: String, bundle: Bundle) { self.init(
        selector: .init(name: name),
        bundle: bundle
    ) }


    @usableFromInline
    init(selector: Selector, bundle: Bundle) {
        self.selector = selector
        self.bundle = bundle
    }



    // MARK: .Selector

    /// Image selector contains all information required to identify an image in a bundle.
    @usableFromInline
    struct Selector : Hashable {

        @usableFromInline
        var name: String


        @usableFromInline
        init(name: String) {
            self.name = name
        }

    }

}
