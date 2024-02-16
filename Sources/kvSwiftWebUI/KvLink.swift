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
//  KvLink.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 02.12.2023.
//

import Foundation



public typealias Link = KvLink



// TODO: DOC
/// Consider ``KvText/link(_:)`` modifier when a link
public struct KvLink<Label> : KvView
where Label : KvView
{

    @usableFromInline
    let url: URL

    @usableFromInline
    let label: Label



    // TODO: DOC
    @inlinable
    public init(destination: URL, @KvViewBuilder label: () -> Label) {
        self.url = destination
        self.label = label()
    }



    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: Label == Text

extension KvLink where Label == Text {

    // TODO: DOC
    @inlinable
    public init(_ titleKey: KvLocalizedStringKey, destination: URL) {
        self.url = destination
        self.label = Text(titleKey)
    }


    // TODO: DOC
    @inlinable
    public init<S>(_ title: S, destination: URL) where S : StringProtocol {
        self.url = destination
        self.label = Text(title)
    }

}



// MARK: : KvHtmlRenderable

extension KvLink : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        context.representation { context, htmlAttributes in
            let fragment = label.htmlRepresentation(in: context)

            return KvLinkKit.representation(url: url, htmlAttributes: htmlAttributes, innerHTML: fragment)
        }
    }

}



// MARK: - KvLinkKit

struct KvLinkKit {

    /// This code is extracted to be reused, e.g. in ``KvText`` having link attribute.
    static func representation(url: URL,
                               htmlAttributes: KvHtmlKit.Attributes? = nil,
                               innerHTML: KvHtmlRepresentation.Fragment
    ) -> KvHtmlRepresentation.Fragment {
        .tag(
            .a,
            attributes: .union(
                htmlAttributes,
                .init {
                    $0.set(href: url)
                    // - NOTE: URLs having explicit host are considered external so `target="_blank"` attribute is set.
                    if url.host != nil {
                        $0[.target] = "_blank"
                    }
                }
            ),
            innerHTML: innerHTML
        )
    }

}
