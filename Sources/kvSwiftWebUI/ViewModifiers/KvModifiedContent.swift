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
//  KvModifiedContent.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 26.03.2024.
//

public typealias ModifiedContent = KvModifiedContent



public struct KvModifiedContent<Content, Modifier> {

    public var content: Content

    public var modifier: Modifier


    @inlinable
    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

}



extension KvModifiedContent : KvViewModifier
where Content : KvViewModifier, Modifier : KvViewModifier
{

    public func body(content view: Content.Content) -> Modifier.Body {
        modifier.apply(to: content.body(content: view))
    }

}
