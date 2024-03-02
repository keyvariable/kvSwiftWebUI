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
//  KvAnyShapeStyle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.11.2023.
//

public typealias AnyShapeStyle = KvAnyShapeStyle



public struct KvAnyShapeStyle : KvShapeStyle {

    /// - Parameter property: Optional name of CSS property. Pass `nil` to use default value.
    typealias CssStyleProvider = (borrowing KvHtmlContext, _ property: String?) -> String


    let cssBackgroundStyle: CssStyleProvider
    let cssForegroundStyle: CssStyleProvider

    /// - Returns: The receiver reduced to a single color to be used as foreground if possible.
    let foregroundColor: () -> KvColor?
    /// - Returns: The receiver reduced to a single color to be used as background if possible.
    let backgroundColor: () -> KvColor?
    /// - Returns: The receiver reduced to a single color to be used as background if possible. E.g. it matches bottom color of gradient.
    let bottomBackgroundColor: () -> KvColor?


    // MARK: : KvShapeStyle

    @inlinable
    public func eraseToAnyShapeStyle() -> KvAnyShapeStyle { self }

}
