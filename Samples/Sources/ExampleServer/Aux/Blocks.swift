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
//  Blocks.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 23.11.2023.
//

import kvCssKit
import kvSwiftWebUI



struct BlockConstants {

    static let rootPadding: KvCssLength = .vw(1) + .vh(1)
    static let maximumRegularWidth: KvCssLength = 1024

    static let regularWidth: KvCssLength = min(.vw(100), BlockConstants.maximumRegularWidth)
    static let regularContentWidth: KvCssLength = regularWidth - 2 * rootPadding

}



struct FullWidthBlock<Content : View> : View {

    init(foreground: Color = .white, background: Color = .accent, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.foreground = foreground
        self.background = background
    }


    private let content: Content

    private let foreground: Color
    private let background: Color


    // MARK: : View

    var body: some View {
        content
            .padding(BlockConstants.rootPadding)
            .frame(width: .vw(100))
            .foregroundStyle(foreground)
            .background(background)
    }

}



struct RegularBlock<Content : View> : View {

    init(foreground: Color = .label, background: Color = .secondarySystemBackground, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.foreground = foreground
        self.background = background
    }


    private let content: Content

    private let foreground: Color
    private let background: Color


    // MARK: : View

    var body: some View {
        VStack(alignment: .leading, spacing: .em(2)) { content }
            .padding(BlockConstants.rootPadding)
            .padding(.bottom, .em(3))
            .frame(width: BlockConstants.regularWidth, alignment: .leading)
            .background(.systemBackground)
            .frame(width: .vw(100))
            .foregroundStyle(foreground)
            .background(background)
    }

}
