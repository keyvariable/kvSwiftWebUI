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
        let backgroundStyle = Self.firstBackgroundStyle(of: content) ?? KvColor.tertiarySystemBackground.eraseToAnyShapeStyle()

        self.rootRepresentationProvider = { context in
            RootView(backgroundColor: backgroundStyle.bottomBackgroundColor(), content: content)
                .htmlRepresentation(in: context)
        }

        self.backgroundStyle = backgroundStyle
    }



    private let rootRepresentationProvider: (KvHtmlRepresentationContext) -> KvHtmlRepresentation

    /// Background style from the content if provided.
    private let backgroundStyle: KvAnyShapeStyle?



    // MARK: : KvHtmlBody

    func renderHTML(in htmlContext: KvHtmlContext) -> KvHtmlRepresentation {
        // The foundation CSS is required to provide the default styles.
        htmlContext.insert(.foundation)

        return KvHtmlRepresentationContext.root(html: htmlContext, environment: .init(viewConfiguration))
            .representation(options: .noContainer) { context, cssAttributes in
                rootRepresentationProvider(context)
                    .mapBytes { .tag(
                        .body,
                        css: cssAttributes,
                        innerHTML: $0
                    ) }
            }
    }



    // MARK: .RootView

    private struct RootView<Content : KvView> : KvView {

        let backgroundColor: KvColor?
        let content: Content


        init(backgroundColor: KvColor?, content: Content) {
            self.backgroundColor = backgroundColor
            self.content = content
        }


        // MARK: .Constants

        private struct Constants { private init() { }

            static var signatureBannerPadding: KvCssLength { .em(0.25) }

        }


        // MARK: : KvView

        var body: some KvView {
            VStack(spacing: 0) {
                content
                    .frame(minHeight: .vh(100) - (.em(1) + 2 * Constants.signatureBannerPadding))
                signatureBanner
            }
            .frame(minWidth: .vw(100), minHeight: .vh(100))
        }

        private var signatureBanner: some View {
            let backgroundColor = backgroundColor ?? .black

            let text =
            Text("Made with ")
            + Text("kvSwiftWebUI")
                .link(URL(string: "https://github.com/keyvariable/kvSwiftWebUI.git")!)

            return text
                .padding(.horizontal)
                .padding(.vertical, Constants.signatureBannerPadding)
                .frame(width: .percents(100))
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

        if let backgroundStyle, $0.modify(background: backgroundStyle) != nil { assertionFailure("Warning: body background hasn't been applied") }
    } }


    private static func firstBackgroundStyle<V : KvView>(of view: V) -> KvAnyShapeStyle? {
        var view: any View = view

        while true {
            switch view {
            case let modifiedView as KvModifiedView:
                switch modifiedView.environment.viewConfiguration?.background {
                case .some(let background):
                    return background
                case .none:
                    view = modifiedView.sourceProvider()
                }

            case is KvHtmlRenderable:
                return nil

            default:
                view = view.body
            }
        }

        assertionFailure("This code must never be executed")
        return nil
    }

}
