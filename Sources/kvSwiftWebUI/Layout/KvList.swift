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
//  KvList.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 22.05.2024.
//

public typealias List = KvList



// TODO: DOC
/// - SeeAlso: ``KvListStyle``, ``KvView/listStyle(_:)-76ph0``.
public struct KvList<Content> : KvView
where Content : KvView
{

    @usableFromInline
    let content: Content



    @inlinable
    public init(@KvViewBuilder content: () -> Content) {
        self.content = content()
    }



    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvList : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        let spacing = context.environmentNode?.values[viewConfiguration: \.listRowSpacing]
        let listStyle = context.environmentNode?.values[viewConfiguration: \.listStyle] ?? KvDefaultListStyle.sharedErased

        return listStyle.listContainerBlock(context, spacing, content.htmlRepresentation(in:))
    }

}
