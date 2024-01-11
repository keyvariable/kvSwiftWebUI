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
//  KvShapeStyleView.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.11.2023.
//

public struct KvShapeStyleView : KvView {

    @usableFromInline
    let content: KvAnyShapeStyle


    @inlinable
    public init(content: KvAnyShapeStyle) {
        self.content = content
    }


    @inlinable
    public init<S>(content: S) where S : KvShapeStyle {
        self.init(content: content.eraseToAnyShapeStyle())
    }



    // MARK: : KvView

    public var body: some KvView {
        TemplateView(content: content)
    }



    // MARK: .TemplateView

    private struct TemplateView : KvView, KvHtmlRenderable {

        let content: KvAnyShapeStyle


        var body: KvNeverView { Body() }


        func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
            context.representation { context, cssAttributes in
                var htmlBytes: KvHtmlBytes = .tag(.div, css: .init(styles: content.cssBackgroundStyle(context.html, nil), "width:100%;height:100%"))

                if let cssAttributes = cssAttributes {
                    htmlBytes = .tag(.div, css: cssAttributes, innerHTML: htmlBytes)
                }

                return .init(bytes: htmlBytes)
            }
        }

    }

}
