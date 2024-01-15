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
//  KvImage.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.11.2023.
//

import Foundation

import kvCssKit



public typealias Image = KvImage



// TODO: DOC
public struct KvImage : KvView {

    @usableFromInline
    let resource: KvImageResource

    @usableFromInline
    private(set) var resizingMode: ResizingMode? = nil

    @usableFromInline
    private(set) var renderingMode: TemplateRenderingMode? = nil


    // TODO: DOC
    @inlinable
    public init(_ name: String, bundle: Bundle? = nil) { self.init(KvImageResource(name: name, bundle: bundle ?? .main)) }


    // TODO: DOC
    @inlinable
    public init(_ resource: KvImageResource) { self.resource = resource }



    // MARK: .ResizingMode

    // TODO: DOC
    public enum ResizingMode : Hashable {

        // TODO: DOC
        case stretch
        // TODO: DOC
        case tile

    }



    // MARK: .TemplateRenderingMode

    // TODO: DOC
    public enum TemplateRenderingMode : Hashable {

        // TODO: DOC
        case original
        // TODO: DOC
        case template

    }



    // MARK: : KvView

    public var body: KvNeverView { Body() }



    // MARK: Modifiers

    // TODO: DOC
    @inlinable
    public consuming func resizable(resizingMode: ResizingMode = .stretch) -> KvImage {
        var copy = self
        copy.resizingMode = resizingMode
        return copy
    }


    // TODO: DOC
    @inlinable
    public consuming func renderingMode(_ renderingMode: TemplateRenderingMode?) -> KvImage {
        var copy = self
        copy.renderingMode = renderingMode
        return copy
    }

}



// MARK: : KvHtmlRenderable

extension KvImage : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        switch renderingMode {
        case .original, nil:
            return context.representation { context, cssAttributes in
                renderContentHTML(in: context, cssAttributes: cssAttributes, alignment: context.environment?[viewConfiguration: \.frame]?.alignment)
            }

        case .template:
            return context.representation { context, cssAttributes in
                let alignment = context.environment?[viewConfiguration: \.frame]?.alignment
                let mask = cssBackground(in: context, alignment: alignment)

                let resizingCssAttributes: KvHtmlKit.CssAttributes? = resizingMode != nil ? .init(classes: "resizable") : nil

                var fragment = context
                    .representation(cssAttributes: .union(.init(style: "display:block;visibility:hidden"), resizingCssAttributes)) { context, cssAttributes in
                        renderContentHTML(in: context, cssAttributes: cssAttributes, alignment: alignment)
                    }

                // Two containers are used to separate context's background and the mask background.

                fragment = .tag(
                    .div,
                    css: .union(
                        .init(styles: context.environment?[\.foregroundStyle]?.cssBackgroundStyle(context.html, nil),
                              "-webkit-mask:\(mask.css);mask:\(mask.css)"),
                        resizingCssAttributes
                    ),
                    innerHTML: fragment
                )

                return .tag(.div, css: .union(cssAttributes, resizingCssAttributes), innerHTML: fragment)
            }
        }
    }


    private func cssBackground(in context: KvHtmlRepresentationContext, alignment: KvAlignment?) -> KvCssBackground {
        .init(repeat: resizingMode == .tile ? .repeat : .noRepeat,
              source: .uri(context.html.uri(for: resource)),
              position: alignment?.cssBackgroundPosition)
    }


    private func renderContentHTML(
        in context: KvHtmlRepresentationContext,
        cssAttributes: borrowing KvHtmlKit.CssAttributes?,
        alignment: @autoclosure () -> KvAlignment?
    ) -> KvHtmlRepresentation.Fragment {
        switch resizingMode {
        case .stretch:
            renderImgHTML(
                in: context,
                cssAttributes: .union(
                    cssAttributes,
                    .init(classes: "resizable", styles: alignment()?.cssObjectPosition, "object-fit:contain")
                )
            )

        case .tile:
            renderDivHTML(in: context, alignment: alignment(), cssAttributes: cssAttributes)

        case nil:
            renderImgHTML(in: context, cssAttributes: cssAttributes)
        }
    }


    private func renderImgHTML(
        in context: KvHtmlRepresentationContext,
        cssAttributes: borrowing KvHtmlKit.CssAttributes?
    ) -> KvHtmlRepresentation.Fragment {
        let uri = context.html.uri(for: resource)
        let src: KvHtmlKit.Attribute = .src(consume uri)

        return .tag(.img, css: cssAttributes, attributes: src)
    }


    private func renderDivHTML(
        in context: KvHtmlRepresentationContext,
        alignment: KvAlignment?,
        cssAttributes: borrowing KvHtmlKit.CssAttributes?
    ) -> KvHtmlRepresentation.Fragment {
        let cssAttributes: KvHtmlKit.CssAttributes? = .union(
            cssAttributes,
            .init(classes: "resizable", styles: "background:\(cssBackground(in: context, alignment: alignment).css)")
        )

        return .tag(.div, css: cssAttributes)
    }

}
