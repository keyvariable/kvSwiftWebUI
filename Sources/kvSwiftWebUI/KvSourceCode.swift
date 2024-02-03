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
//  KvSourceCode.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.11.2023.
//

public typealias SourceCode = KvSourceCode



// TODO: Integrate with a syntax highlighter.
// TODO: DOC
public struct KvSourceCode {

    @usableFromInline
    let content: String

    @usableFromInline
    var font: KvFont?



    @inlinable
    public init(_ content: String) {
        self.content = content
    }



    // MARK: .Defaults

    private struct Defaults {

        static let font = KvFont.system(.body, design: .monospaced)

    }



    // MARK: Modifiers

    @inlinable
    consuming public func font(_ font: KvFont) -> Self {
        var copy = self
        copy.font = font
        return copy
    }

}



// MARK: : KvView

extension KvSourceCode : KvView {

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvSourceCode : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        context.representation(htmlAttributes: .init { $0.append(styles: "overflow-x:scroll") }) { context, htmlAttributes in
            let fragment = KvText(verbatim: content)
                .font(font ?? Defaults.font)
                .htmlRepresentation(in: context)

            return .tag(.div, attributes: htmlAttributes ?? .empty, innerHTML: .tag(.pre, innerHTML: fragment))
        }
    }

}
