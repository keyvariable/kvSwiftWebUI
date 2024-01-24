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

import kvHttpKit



public typealias NavigationLink = KvNavigationLink



// TODO: DOC
public struct KvNavigationLink<Label> : KvView
where Label : KvView
{

    @usableFromInline
    let label: Label

    @usableFromInline
    let path: Path


    @usableFromInline
    init(path: Path, label: Label) {
        self.label = label
        self.path = path
    }


    // TODO: DOC
    @inlinable
    public init<D>(value: D, @KvViewBuilder label: () -> Label)
    where D : LosslessStringConvertible
    {
        self.init(path: .component(value.description), label: label())
    }


    // TODO: DOC
    @inlinable
    public init<D>(value: D, @KvViewBuilder label: () -> Label)
    where D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(value: value.rawValue, label: label)
    }


    // TODO: DOC
    public init(path: KvNavigationPath, @KvViewBuilder label: () -> Label) {
        self.init(path: .absolute(path.urlPath), label: label())
    }


    // TODO: DOC
    @inlinable
    public init<D>(_ titleKey: KvLocalizedStringKey, value: D)
    where Label == KvText, D : LosslessStringConvertible
    {
        self.init(path: .component(value.description), label: KvText(titleKey))
    }


    // TODO: DOC
    @inlinable
    public init<D>(_ titleKey: KvLocalizedStringKey, value: D)
    where Label == KvText, D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(titleKey, value: value.rawValue)
    }


    // TODO: DOC
    public init(_ titleKey: KvLocalizedStringKey, path: KvNavigationPath)
    where Label == KvText
    {
        self.init(path: .absolute(path.urlPath), label: KvText(titleKey))
    }

    
    // TODO: DOC
    @inlinable
    public init<S, D>(_ title: S, value: D)
    where Label == KvText, S : StringProtocol, D : LosslessStringConvertible
    {
        self.init(path: .component(value.description), label: KvText(title))
    }


    // TODO: DOC
    @inlinable
    public init<S, D>(_ title: S, value: D)
    where Label == KvText, S : StringProtocol, D : RawRepresentable, D.RawValue : LosslessStringConvertible
    {
        self.init(title, value: value.rawValue)
    }


    // TODO: DOC
    public init<S>(_ title: S, path: KvNavigationPath)
    where Label == KvText, S : StringProtocol
    {
        self.init(path: .absolute(path.urlPath), label: KvText(title))
    }


    // MARK: .Path

    @usableFromInline
    enum Path {
        case absolute(KvUrlPath)
        case component(String)
    }


    // MARK: : KvView

    public var body: KvNeverView { Body() }


    // MARK: Operations

    private func url(in context: KvHtmlRepresentationContext) -> URL? {
        var components = URLComponents()

        switch path {
        case .absolute(let urlPath):
            components.path = "/\(urlPath.joined)"
        case .component(let component):
            let contextPath = context.html.absolutePath
            let prefix = !contextPath.isEmpty ? "/\(contextPath.joined)" : ""
            components.path = "\(prefix)/\(component)"
        }

        guard let url = components.url else {
            assertionFailure("WARNING: unable to compose navigation URL from components: \(components)")
            return nil
        }
        return url
    }

}



// MARK: : KvHtmlRenderable

extension KvNavigationLink : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        switch url(in: context) {
        case .some(let url):
            KvLink(destination: url, label: { label })
                .renderHTML(in: context)
        case .none:
            label
                .htmlRepresentation(in: context)
        }
    }

}
