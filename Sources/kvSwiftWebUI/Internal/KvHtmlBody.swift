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
//  KvHtmlBody.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 28.12.2023.
//

import Foundation

import kvCssKit



// MARK: - KvHtmlBody

protocol KvHtmlBody {

    func renderHTML(in htmlContext: KvHtmlContext) -> KvHtmlRepresentation

}



// MARK: - KvHtmlBodyImpl

struct KvHtmlBodyImpl : KvHtmlBody {

    init<Content : KvView>(content: Content) {
        self.rootRepresentationProvider = { context in
            KvHtmlRepresentation(of: BodyView(with: content), in: context)
        }
    }



    private let rootRepresentationProvider: (KvHtmlRepresentationContext) -> KvHtmlRepresentation



    // MARK: .Constants

    private struct Constants { private init() { }

        static let backgroundColor = KvColor.tertiarySystemBackground

    }



    // MARK: : KvHtmlBody

    func renderHTML(in htmlContext: KvHtmlContext) -> KvHtmlRepresentation {
        // The foundation CSS is required to provide the default styles.
        htmlContext.insert(.foundation)

        var environment = KvEnvironmentValues(viewConfiguration)
        environment.navigationPath = htmlContext.navigationPath

        return rootRepresentationProvider(.root(html: htmlContext, environment: environment))
    }



    // MARK: .BodyView

    private struct BodyView<Content : KvView> : KvView, KvHtmlRenderable {

        let content: Content


        init(with content: Content) {
            self.content = content
        }


        // MARK: : KvView

        var body: KvNeverView { Body() }


        // MARK: : KvHtmlRenderable

        func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
            context.representation(options: .noContainer) { context, cssAttributes in
                /// Finalized HTML representation is generated here to collect some view information (e.g. first background style, navigation title, etc.) and use it below.
                let representation = KvHtmlRepresentation(of: content, in: context)

                let backgroundStyle = context.html.backgroundStyle ?? Constants.backgroundColor.eraseToAnyShapeStyle()

                let rootView = RootView(
                    backgroundColor: backgroundStyle.bottomBackgroundColor() ?? Constants.backgroundColor,
                    content: RepresentationView(representation)
                )

                let fragment = rootView.htmlRepresentation(in: context)

                let extraCSS = KvViewConfiguration {
                    if $0.modify(background: backgroundStyle) != nil { assertionFailure("Warning: body background hasn't been applied") }
                }
                .cssAttributes(in: context)

                return .tag(.body, css: .union(cssAttributes, extraCSS), innerHTML: fragment)
            }
        }


        // MARK: .RepresentationView

        /// Dedicated view used to insert HTML representations in a view hierarchy.
        ///
        /// - Warning: Be careful with the contexts. It's better to render `RepresentationView` in the same context as the representation or it's sub-context.
        private struct RepresentationView : KvView, KvHtmlRenderable {

            let representation: KvHtmlRepresentation


            init(_ representation: KvHtmlRepresentation) {
                self.representation = representation
            }


            // MARK: : KvView

            var body: KvNeverView { Body() }


            // MARK: : KvHtmlRenderable

            func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
                .init(.dataList(representation))
            }

        }

    }



    // MARK: .RootView

    private struct RootView<Content : KvView> : KvView {

        let backgroundColor: KvColor
        let content: Content


        // MARK: .Constants

        private struct Constants { private init() { }

            static var signatureBannerPadding: KvCssLength { .em(0.25) }

        }


        // MARK: : KvView

        var body: some KvView {
            VStack(spacing: 0) {
                content
                signatureBanner
            }
        }

        private var signatureBanner: some View {
            let text =
            Text("Made with ")
            + Text("kvSwiftWebUI")
                .link(URL(string: "https://github.com/keyvariable/kvSwiftWebUI.git")!)

            return text
                .padding(.horizontal)
                .padding(.vertical, Constants.signatureBannerPadding)
                .frame(width: .vw(100))
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(.footnote).weight(.light))
                .foregroundStyle(backgroundColor.label.tertiary)
                .background(backgroundColor)
        }

    }



    // MARK: Auxiliaries

    private var viewConfiguration: KvViewConfiguration { .init {
        $0.foregroundStyle = Color.label.eraseToAnyShapeStyle()
        $0.font = .body
    } }

}
