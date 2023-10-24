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
//  KvHtmlDocument.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 07.11.2023.
//

import Foundation

import kvCssKit
import kvHttpKit



struct KvHtmlDocument {

    init<Content : KvView>(_ content: @escaping () -> Content, in context: KvHtmlContext) {
        let body = BodyView(content: content).renderHTML(in: context)
        self.context = context

        // Documents use foundation CSS.
        context.insert(.foundation)

        titleBytes = body.title.map { .joined("<title>", $0, "</title>") } ?? .empty

        bodyBytes = body.bytes
    }



    private let context: KvHtmlContext

    private let titleBytes: KvHtmlBytes
    private let bodyBytes: KvHtmlBytes



    // MARK: : Operations

    func representation(rootPath: KvUrlPath?) -> KvHtmlBytes {
        return .joined(
            "<!DOCTYPE html><html><head>",
            titleBytes,
            .joined(context.resources().lazy.compactMap { $0.linkHtmlBytes(relativeTo: rootPath) }),
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />",
            "<meta name=\"format-detection\" content=\"telephone=no\" /><meta name=\"format-detection\" content=\"date=no\" /><meta name=\"format-detection\" content=\"address=no\" /><meta name=\"format-detection\" content=\"email=no\" />",
            .joined(context.headers),
            "</head>",
            bodyBytes,
            "</html>"
        )
    }



    // MARK: .BodyView

    private struct BodyView<Content : KvView> {

        private let rootView: RootView

        /// Background style from the content if provided.
        private let backgroundStyle: KvAnyShapeStyle?


        init(content: () -> Content) {
            let content = content()
            let backgroundStyle = Self.firstBackgroundStyle(of: content) ?? KvColor.tertiarySystemBackground.eraseToAnyShapeStyle()

            rootView = RootView(backgroundColor: backgroundStyle.bottomBackgroundColor(), content: content)

            self.backgroundStyle = backgroundStyle
        }


        // MARK: RootView

        private struct RootView : KvView {

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


        // MARK: HTML

        func renderHTML(in htmlContext: KvHtmlContext) -> KvHtmlRepresentation {
            KvHtmlRepresentationContext(html: htmlContext, viewConfiguration: viewConfiguration)
                .representation(options: .noContainer) { context, cssAttributes, viewConfiguration in
                    rootView
                        .htmlRepresentation(in: context)
                        .mapBytes { .tag(
                            .body,
                            css: cssAttributes,
                            innerHTML: $0
                        ) }
                }
        }


        private var viewConfiguration: KvViewConfiguration { .init(
            appearance: .init(foregroundStyle: Color.label.eraseToAnyShapeStyle(), font: .body),
            container: .init(background: backgroundStyle)
        ) }


        // MARK: Auxiliaries

        private static func firstBackgroundStyle<V : KvView>(of view: V) -> KvAnyShapeStyle? {
            var view: any View = view

            while true {
                switch view {
                case let modifiedView as KvModifiedView:
                    switch modifiedView.configuration.container?.background {
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

}
