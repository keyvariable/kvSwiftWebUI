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



/// A view providing default page structure: header with title, subtitle, optional back navigation links, optional reference to source file on GitHub.
///
/// - SeeAlso: ``NavigationPathView``.
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
            HeaderBlock {
                VStack(spacing: 0) {
                    VStack(spacing: .em(1.35)) {
                        title
                            .font(.largeTitle)
                        subtitle
                            .frame(maxWidth: min(.vw(100), BlockConstants.maximumRegularWidth) - 2 * BlockConstants.rootPadding)
                    }
                    .padding(.vertical, .em(2))

                    NavigationPathView()
                        .font(.footnote)
                        .frame(width: BlockConstants.regularContentWidth, alignment: .leading)
                }
            }

            RegularBlock {
                sourceFilePath.map {
                    SourceLink(to: $0)
                        .font(.footnote)
                }

                content
            }
        }
        /// HTML representation uses first background in `<body>` tag.
        /// `Page` type is designated to be the first top-level view so it's background to passed to `<body>` tag.
        ///
        /// - Note: The background matches background of `HeaderBlock`.
        ///         If browser extend pages to provide scroll bouncing then the header looks infinite in upward direction.
        ///         Also Safari tints bars using the background.
        .background(.accent)
        .navigationTitle(title)
        /// This view modifier declares common keywords.
        .modifier(PageKeywordModifier())
    }

}



/// Declaration of the keywords is extracted to a view modifier to reuse on custom pages, e.g. ``ColorDetailView``.
struct PageKeywordModifier : ViewModifier {

    func body(content: Content) -> some View {
        /// `.metadata(keywords:)` modifier specifies keywords in document's metadata.
        /// Keywords of all views in a document are joined.
        /// Common keywords are defined here.
        ///
        /// - Note: Keywords are localized.
        content
            .metadata(keywords: Text("Swift"), Text("cross-platform"), Text("SwiftUI"), Text("web"), Text(verbatim: "ExampleServer"), Text(verbatim: "kvSwiftWebUI"))
    }

}
