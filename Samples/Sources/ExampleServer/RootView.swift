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



struct RootView : View {

    // MARK: : View

    var body: some View {
        Page(title: Text("\"ExampleServer\" Sample"),
             subtitle: Text("A sample server application with simple HTML frontend on kvSwiftWebUI framework."),
             sourceFilePath: "RootView.swift"
        ) {
            BodySection {
                Text("kvSwiftWebUI").link(Constants.kvSwiftWebUI_GitHubURL)
                + .space + Text("is a cross-platform framework providing API to declare web-interfaces in a way very close to SwiftUI framework.")
                + .space + Text("kvSwiftWebUI allows to implement web interfaces in a declarative paradigm.")
                + .space + Text("kvSwiftWebUI minimizes efforts to create and maintain boilerplate code, it allows developer to focus on the design of the interface and the source code.")

                Text("Developed interfaces have to be served. In this example the backend is served with")
                + .space + Text(verbatim: "kvServerKit").link(Constants.kvServerKit_GitHubURL)
                + .space + Text("framework.")
            }

            Section1(header: Text("Contents")) {
                articleLinkSection(.basics, header: Text("The Basics")) {
                    Text("This article contains small examples of working with views and view modifiers.")
                    + .space + Text("Building hierarchies from modified views allows you to create complex and beautiful web interfaces.")
                }

                articleLinkSection(.colors, header: Text("Colors")) {
                    Text("Web sites are often organized in a hierarchy of pages.")
                    + .space + Text("This simple example shows a catalog of some colors available in kvSwiftWebUI framework.")
                    + .space + Text("kvSwiftWebUI automatically generates links to pages.")
                }
            }
        }
        .navigationDestination(for: Article.self) { article in
            switch article {
            case .basics:
                BasicsView()
            case .colors:
                ColorCatalogView()
            }
        }
    }


    private enum Article : String {
        case basics
        case colors
    }


    private func articleLinkSection<Content : View>(_ article: Article, header: Text, @ViewBuilder content: () -> Content) -> some View {
        Section2(header: { NavigationLink(value: article, label: { header }) }) {
            content()
            NavigationLink("View article", value: article)
        }
    }

}
