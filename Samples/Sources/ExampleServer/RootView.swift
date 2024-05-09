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
//  RootView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 10.01.2024.
//

import kvSwiftWebUI



/// The root view of frontend.
///
/// It contains an introduction and links to articles.
///
/// `View` is a protocol all views have to implement.
struct RootView : View {

    // MARK: : View

    /// Views have to provide its contents in `body` property.
    /// The resulting type is inferred automatically at compile time.
    var body: some View {
        /// A view providing default page structure: header with title, subtitle, optional back navigation links, optional reference to source file on GitHub.
        /// This structure is incapsulated to ``Page`` type and reused.
        ///
        /// See ``ColorDetailView`` for a view having custom structure.
        Page(title: Text("\"ExampleServer\" Sample"),
             subtitle: Text("A sample server application with simple HTML frontend on kvSwiftWebUI framework"),
             sourceFilePath: "RootView.swift"
        ) {
            /// Page contents are organized to sections: ``Section1``, ``Section2``, ``BodySection``.

            /// Declarations can be reused. Text below is reused as introduction and as HTML document's description metadata.
            ///
            /// `Text` provides limited support of [Markdown](https://www.markdownguide.org ).
            /// `Text` automatically looks up for supported *Markdown* expressions in localized values.
            ///
            /// Some expressions (e.g. HTML special characters) are ignored by default.
            /// Use `Text.md(_:tableName:bundle:comment:)` fabric to force *Markdown* processing.
            let overview = Text("""
                [kvSwiftWebUI](\(Constants.kvSwiftWebUI_GitHubURL)) is a cross-platform framework providing API to declare web-interfaces in a way very close to SwiftUI framework.
                It allows to implement web interfaces in a declarative paradigm.
                kvSwiftWebUI minimizes efforts to create and maintain boilerplate code allowing developer to focus on the design of the interface and the source code.
                """)

            BodySection {
                overview

                Text("""
                    The declared interfaces have to be served.
                    In this example the backend is served with [kvServerKit](\(Constants.kvServerKit_GitHubURL)) framework.
                    """)
            }
            /// As `.navigationTitle(_:)`, if several views declare description metadata in a navigation destination then the first description is used and others are ignored.
            .metadata(description: overview)

            Section1(header: Text("Contents")) {
                /// Views for a collection of values can be declared via `ForEach` view.
                /// Block returning a view is called for each element of provided collection.
                ForEach(Article.allCases, id: \.self) { article in
                    Section2(header: { NavigationLink(value: article, label: { article.header }) }) {
                        article.overview
                        NavigationLink("View article", value: article)
                    }
                }
            }
        }
        /// Value passed to `navigationTitle` modifier is used as a document title.
        .navigationTitle("ExampleServer | kvSwiftWebUI")
        /// Navigation destinations are defined with `navigationDestination` modifier.
        ///
        /// For example, this declaration provides destinations for ``Article`` type.
        /// This type is a string representable enumeration.
        /// So the destinations are available at `.rawValue` relative paths.
        ///
        /// See ``ColorCatalogView/body`` for example of several navigation destinations.
        .navigationDestination(for: Article.self) { article in
            switch article {
            case .basics:
                BasicsView()
            case .colors:
                ColorCatalogView()
            case .scripts:
                ScriptView()
            }
        }
        /// This modifier provides keyword metadata for the resulting navigation destination.
        /// If several views declare keyword metadata in a navigation destination then all the keywords are joined.
        ///
        /// - Note: Keywords are localized.
        ///
        /// - SeeAlso: `.metadata(description:)` modifier.
        ///
        /// - Tip: Use `Text(verbatim:)` to prevent localization of argument.
        .metadata(keywords: Text("example"), Text("articles"))
    }


    private enum Article : String, CaseIterable, Hashable {

        case basics
        case colors
        case scripts


        var header: Text {
            switch self {
            case .basics: Text("The Basics")
            case .colors: Text("Colors")
            case .scripts: Text("Scripts")
            }
        }

        var overview: Text {
            switch self {
            case .basics:
                Text("""
                    This article contains small examples of working with views and view modifiers. \
                    Building hierarchies from modified views allows you to create complex and beautiful web interfaces.
                    """)

            case .colors:
                Text("""
                    Web sites are often organized in a hierarchy of pages. \
                    This simple example shows a catalog of some colors available in kvSwiftWebUI framework. \
                    kvSwiftWebUI automatically generates links to pages.
                    """)

            case .scripts:
                Text("""
                    Scripts are widely used to provide various functionality in HTML documents. \
                    This article contains some examples of working with scripts.
                    """)
            }
        }

    }

}
