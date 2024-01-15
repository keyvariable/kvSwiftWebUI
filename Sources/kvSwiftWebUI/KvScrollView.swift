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
//  KvScrollView.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 28.11.2023.
//

public typealias ScrollView = KvScrollView



// TODO: DOC
public struct KvScrollView<Content : KvView> : KvView {

    @usableFromInline
    let content: Content

    @usableFromInline
    let axes: KvAxis.Set



    // TODO: DOC
    @inlinable
    public init(_ axes: KvAxis.Set = .vertical, @KvViewBuilder content: () -> Content) {
        self.content = content()
        self.axes = axes
    }



    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvScrollView : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {

        func OverflowCSS(scroll: Bool) -> String { scroll ? "auto" : "visible" }


        let scrollCSS: KvHtmlKit.CssAttributes = .init(
            styles: "overflow:\(OverflowCSS(scroll: axes.contains(.horizontal))) \(OverflowCSS(scroll: axes.contains(.vertical)))",
            axes.contains(.horizontal) ? "width:100%" : nil,
            axes.contains(.vertical) ? "height:100%" : nil
        )

        return context.representation(cssAttributes: scrollCSS) { context, cssAttributes in
            var fragment = content.htmlRepresentation(in: context)

            // Inner container
            fragment = .tag(.div, css: .init(styles: "width:fit-content;height:fit-content"), innerHTML: fragment)

            return .tag(.div, css: cssAttributes, innerHTML: fragment)
        }
    }

}
