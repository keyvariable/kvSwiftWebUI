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
//  KvNavigationStack.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 19.12.2023.
//

public typealias NavigationStack = KvNavigationStack



// TODO: DOC
public struct KvNavigationStack<Root> : KvView
where Root : KvView
{

    @usableFromInline
    let rootView: Root


    // TODO: DOC
    @inlinable
    public init(@KvViewBuilder root: () -> Root) {
        rootView = root()
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvNavigationStack : KvHtmlRenderable {

    func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
        rootView.htmlRepresentation(in: context)
    }

}
