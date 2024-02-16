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
//  KvVStack.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 12.11.2023.
//

import kvCssKit



public typealias VStack = KvVStack



// TODO: DOC
public struct KvVStack<Content> : KvView
where Content : KvView
{

    @usableFromInline
    let alignment: KvHorizontalAlignment

    @usableFromInline
    let spacing: KvCssLength?

    @usableFromInline
    let content: Content


    @inlinable
    public init(alignment: KvHorizontalAlignment = .center, spacing: KvCssLength? = nil, @KvViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvVStack : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        context.representation(
            containerAttributes: .stack(.vertical),
            htmlAttributes: .init {
                $0.insert(classes: "flexV",
                          context.html.cssFlexClass(for: KvVerticalAlignment.center, as: .mainContent),
                          context.html.cssFlexClass(for: alignment, as: .crossItems))
                $0.append(styles: "row-gap:\((spacing ?? KvDefaults.vStackSpacing).css)")
            }
        ) { context, htmlAttributes in
            let fragment = content.htmlRepresentation(in: context)

            return .tag(.div, attributes: htmlAttributes ?? .empty, innerHTML: fragment)
        }
    }

}
