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
//  KvUnevenRoundedRectangle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

import kvCssKit



// MARK: - KvRectangleCornerRadii

public typealias RectangleCornerRadii = KvRectangleCornerRadii


// TODO: DOC
public struct KvRectangleCornerRadii : Equatable {

    public var topLeading, bottomLeading, bottomTrailing, topTrailing: KvCssLength


    @inlinable
    public init(topLeading: KvCssLength = 0.0, bottomLeading: KvCssLength = 0.0, bottomTrailing: KvCssLength = 0.0, topTrailing: KvCssLength = 0.0) {
        self.topLeading = topLeading
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
        self.topTrailing = topTrailing
    }


    // MARK: Operations

    var cssBorderRadius: KvCssBorderRadius {
        .init(topLeft: topLeading, topRight: topTrailing, bottomRight: bottomTrailing, bottomLeft: bottomLeading)
    }

}



// MARK: - KvUnevenRoundedRectangle

public typealias UnevenRoundedRectangle = KvUnevenRoundedRectangle


// TODO: DOC
public struct KvUnevenRoundedRectangle : KvShape {

    public var cornerRadii: RectangleCornerRadii



    @inlinable
    public init(cornerRadii: RectangleCornerRadii) {
        self.cornerRadii = cornerRadii
    }


    @inlinable
    public init(topLeadingRadius: KvCssLength = 0.0, bottomLeadingRadius: KvCssLength = 0.0, bottomTrailingRadius: KvCssLength = 0.0, topTrailingRadius: KvCssLength = 0.0) {
        self.init(cornerRadii: .init(topLeading: topLeadingRadius,
                                     bottomLeading: bottomLeadingRadius,
                                     bottomTrailing: bottomTrailingRadius,
                                     topTrailing: topTrailingRadius))
    }



    // MARK: : KvShape

    public var clipShape: KvClipShape {
        .borderRadius(cornerRadii.cssBorderRadius)
    }

}



// MARK: KvShape Integration

extension KvShape where Self == KvUnevenRoundedRectangle {

    // TODO: DOC
    @inlinable
    public static func rect(cornerRadii: KvRectangleCornerRadii) -> Self { .init(cornerRadii: cornerRadii) }


    // TODO: DOC
    @inlinable
    public static func rect(topLeadingRadius: KvCssLength = 0.0,
                            bottomLeadingRadius: KvCssLength = 0.0,
                            bottomTrailingRadius: KvCssLength = 0.0,
                            topTrailingRadius: KvCssLength = 0.0
    ) -> Self {
        .init(topLeadingRadius: topLeadingRadius,
              bottomLeadingRadius: bottomLeadingRadius,
              bottomTrailingRadius: bottomTrailingRadius,
              topTrailingRadius: topTrailingRadius)
    }

}
