//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  KvViewModifier.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 26.03.2024.
//

public typealias ViewModifier = KvViewModifier



// TODO: DOC
/// - Important: Currently `@Environment` is not supported in view modifiers.
public protocol KvViewModifier {

    associatedtype Body : KvView


    typealias Content = KvModifiedView


    // TODO: DOC
    @KvViewBuilder
    func body(content: Content) -> Body

}


// MARK: Concatenation

extension KvViewModifier {

    @inlinable
    public func concat<T>(_ modifier: T) -> KvModifiedContent<Self, T> {
        .init(content: self, modifier: modifier)
    }

}


// MARK: Auxiliaries

extension KvViewModifier {

    @usableFromInline
    func apply<V : KvView>(to view: V) -> Body {
        let content: Content = (view as? KvModifiedView) ?? KvModifiedView(source: { view })

        return body(content: content)
    }

}



// MARK: - View.modifier(_:)

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func modifier<T : KvViewModifier>(_ modifier: T) -> some KvView {
        modifier.apply(to: self)
    }

}
