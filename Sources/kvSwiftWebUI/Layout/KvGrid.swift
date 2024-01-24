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
//  KvGrid.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 25.11.2023.
//

import kvCssKit



public typealias Grid = KvGrid



// TODO: DOC
public struct KvGrid<Content : KvView> : KvView {

    @usableFromInline
    let alignment: KvAlignment

    @usableFromInline
    let horizontalSpacing: KvCssLength?
    @usableFromInline
    let verticalSpacing: KvCssLength?

    @usableFromInline
    let content: Content


    // TODO: DOC
    @inlinable
    public init(alignment: KvAlignment = .center,
                horizontalSpacing: KvCssLength? = nil,
                verticalSpacing: KvCssLength? = nil,
                @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content()
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvGrid : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        let gap = KvCssGap(verticalSpacing ?? KvDefaults.gridVerticalSpacing,
                           horizontalSpacing ?? KvDefaults.gridHorizontalSpacing)

        return context.representation(
            containerAttributes: .grid(alignment),
            cssAttributes: .init(classes: "grid",
                                 context.html.cssFlexClass(for: alignment.vertical, as: .crossItems),
                                 context.html.cssFlexClass(for: alignment.horizontal, as: .mainItems),
                                 style: "gap:\(gap.css)")
        ) { context, cssAttributes in
            let fragment = content.htmlRepresentation(in: context)

            // - NOTE: Styles must be calculated after all the child rows are synthesized and number columns are known.
            return .tag(
                .div,
                css: {
                    var cssAttributes = cssAttributes
                    if let gridColumnCount = context.containerAttributes?.gridColumnCount {
                        cssAttributes?.append(style: "grid-template-columns:repeat(\(gridColumnCount),auto)")
                    }
                    return cssAttributes
                },
                innerHTML: fragment
            )
        }
    }

}
