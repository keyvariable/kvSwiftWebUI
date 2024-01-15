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
//  KvNavigationLink.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 19.12.2023.
//

import Foundation



public typealias NavigationLink = KvNavigationLink



// TODO: DOC
public struct KvNavigationLink<Label> : KvView
where Label : KvView
{

    @usableFromInline
    let label: Label

    @usableFromInline
    let value: String


    @usableFromInline
    init(value: String, label: Label) {
        self.label = label
        self.value = value
    }


    // TODO: DOC
    @inlinable
    public init<D>(value: D, @KvViewBuilder label: () -> Label)
    where D : LosslessStringConvertible
    {
        self.init(value: value.description, label: label())
    }


    // TODO: DOC
    @inlinable
    public init<D>(value: D, @KvViewBuilder label: () -> Label)
    where D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(value: value.rawValue, label: label)
    }


    // TODO: DOC
    @inlinable
    public init<D>(_ titleKey: KvLocalizedStringKey, value: D)
    where Label == KvText, D : LosslessStringConvertible
    {
        self.init(value: value, label: { KvText(titleKey) })
    }


    // TODO: DOC
    @inlinable
    public init<D>(_ titleKey: KvLocalizedStringKey, value: D)
    where Label == KvText, D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(value: value, label: { KvText(titleKey) })
    }

    
    // TODO: DOC
    @inlinable
    public init<S, D>(_ title: S, value: D)
    where Label == KvText, S : StringProtocol, D : LosslessStringConvertible
    {
        self.init(value: value, label: { KvText(title) })
    }


    // TODO: DOC
    @inlinable
    public init<S, D>(_ title: S, value: D)
    where Label == KvText, S : StringProtocol, D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(value: value, label: { KvText(title) })
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }

}



// MARK: : KvHtmlRenderable

extension KvNavigationLink : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        let url: URL? = {
            let contextPath = context.html.absolutePath
            var components = URLComponents()
            components.path = !contextPath.isEmpty ? "/\(contextPath.joined)/\(value)" : value
            guard let url = components.url else {
                assertionFailure("WARNING: string representation of value «\(value)» of a NavigationLink can't be used as a component of URL path")
                return nil
            }
            return url
        }()

        return switch url {
        case .some(let url):
            KvLink(destination: url, label: { label })
                .renderHTML(in: context)
        case .none:
            label
                .htmlRepresentation(in: context)
        }
    }

}
