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
//  KvAnyListStyle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 22.05.2024.
//

import kvCssKit



public struct KvAnyListStyle : KvListStyle {

    typealias WrappingBlock = (borrowing KvHtmlRepresentationContext, _ rowSpacing: KvCssLength?, (borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment) -> KvHtmlRepresentation.Fragment



    /// This block is used to wrap HTML list items. E.g. items of a bullet HTML list are wrapped into `<ul>` tag.
    let listContainerBlock: WrappingBlock



    // MARK: : KvListStyle

    public func eraseToAnyListStyle() -> KvAnyListStyle { self }

}
