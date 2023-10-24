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
//  KvZStack.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 06.12.2023.
//

public typealias ZStack = KvZStack



// TODO: DOC
public struct KvZStack<Content> : KvView
where Content : KvView
{

    @usableFromInline
    let alignment: KvAlignment

    @usableFromInline
    let content: Content


    @inlinable
    public init(alignment: KvAlignment = .center, @KvViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvZStack : KvHtmlRenderable {

    func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {

        // - NOTE: ZStack is implemented as a 1x1 CSS grid.

        context.representation(
            containerAttributes: .stack(.horizontal),
            cssAttributes: .init(
                classes: "zstack",
                context.html.cssFlexClass(for: alignment.horizontal, as: .mainContent),
                context.html.cssFlexClass(for: alignment.vertical, as: .crossItems),
                style: "max-width:100%"
            )
        ) { context, cssAttributes, viewConfiguration in
            content
                .htmlRepresentation(in: context)
                .mapBytes { .tag(.div, css: cssAttributes, innerHTML: $0) }
        }
    }

}
