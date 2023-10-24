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
//  KvClipShape.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

import kvCssKit



public struct KvClipShape {

    let content: Content



    // MARK: Fabrics

    static func borderRadius(_ radius: KvCssBorderRadius) -> Self {
        .init(content: .borderRadius(radius))
    }



    // MARK: .Content

    enum Content {

        /// A clip shape is provided via `border-radius` CSS style.
        case borderRadius(KvCssBorderRadius)

    }



    // MARK: CSS

    var css: KvHtmlKit.CssAttributes {
        switch content {
        case .borderRadius(let borderRadius):
            return .init(style: "overflow:hidden;border-radius:\(borderRadius.css)")
        }
    }

}
