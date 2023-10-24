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
//  KvRoundedRectangle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 29.11.2023.
//

import kvCssKit



public typealias RoundedRectangle = KvRoundedRectangle



// TODO: DOC
public struct KvRoundedRectangle : KvShape {

    public var cornerSize: KvCssSize



    // TODO: DOC
    @inlinable
    public init(cornerSize: KvCssSize) {
        self.cornerSize = cornerSize
    }


    // TODO: DOC
    @inlinable
    public init(cornerRadius: KvCssLength) { self.init(cornerSize: .init(width: cornerRadius, height: cornerRadius)) }



    // MARK: : KvShape

    public var clipShape: KvClipShape {
        .borderRadius(.init(KvCssBorderRadius.CornerRadii(x: cornerSize.width, y: cornerSize.height)))
    }

}



// MARK: KvShape Integration

extension KvShape where Self == KvRoundedRectangle {

    // TODO: DOC
    @inlinable
    public static func rect(cornerRadius: KvCssLength) -> Self { .init(cornerRadius: cornerRadius) }


    // TODO: DOC
    @inlinable
    public static func rect(cornerSize: KvCssSize) -> Self { .init(cornerSize: cornerSize) }

}
