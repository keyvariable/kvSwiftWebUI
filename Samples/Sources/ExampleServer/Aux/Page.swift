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
//  Page.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 10.01.2024.
//

import kvCssKit
import kvSwiftWebUI



struct Page<Content : View> : View {

    init(title: Text, subtitle: Text, sourceFilePath: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.sourceFilePath = sourceFilePath
        self.content = content()
    }


    private let title: Text
    private let subtitle: Text

    private let sourceFilePath: String?

    private let content: Content


    // MARK: : View

    var body: some View {
        VStack(spacing: 0) {
            FullWidthBlock {
                VStack(spacing: .em(1.35)) {
                    title
                        .font(.largeTitle)
                    subtitle
                        .frame(maxWidth: min(.vw(100), BlockConstants.maximumRegularWidth) - 2 * BlockConstants.rootPadding)
                }
                .padding(.vertical, .em(2))
            }

            RegularBlock {
                sourceFilePath.map {
                    SourceLink(to: $0)
                        .font(.footnote)
                }

                content
            }
        }
        /// It's for browsers extensing pages to provide scroll bouncing.
        /// The background matches the title background so the title looks infinite in upward direction.
        .background(.accent)
        .navigationTitle(title)
    }

}
