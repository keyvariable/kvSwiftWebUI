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
//  LocalizedHelloView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.02.2024.
//

import kvSwiftWebUI

import Foundation



struct LocalizedHelloView : View {

    /// Current localization context is available in the environment at `\.localization` key path.
    ///
    /// Here it's used to print current language tag.
    @KvEnvironment(\.localization) private var localization


    var body: some View {
        VStack(spacing: 0) {
            Text("HELLO")
                .font(.largeTitle)
                .padding(.vertical, .em(2))

            Group {
                /// - Note: *Markdown* is used to style text as source code.
                Text("`.languageTag == \(localization.languageTag.map { "\"\($0)\"" } ?? "nil")`")
                    .padding(.bottom, .em(2))

                localizationMenu
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 640)
            }
            .font(.footnote.leading(.loose))
            .foregroundStyle(.label.secondary)
        }
        .padding(.horizontal, .em(0.5))
        .padding(.bottom, .em(2))
        /// *kvSwiftWebUI* provides complete support of `Text` arguments in string interpolations: localization, formatting, Markdown.
        .navigationTitle("\(Text("HELLO")) | LocalizedHello")
        /// This modifier specifies text to use as document's description metadata. It's used for SEO.
        /// Also *kvSwiftWebUI* automatically generates sitemaps and *robots.txt* file.
        ///
        /// - Note: Descriptions are localized.
        .metadata(description: "METADATA.DESCRIPTION")
        /// This modifier provides keyword metadata for the resulting navigation destination.
        /// If several views declare keyword metadata in a navigation destination then all the keywords are joined.
        ///
        /// - Note: Keywords are localized.
        ///
        /// - Tip: Use `Text(verbatim:)` to prevent localization of argument.
        .metadata(keywords: Text("HELLO"), Text(verbatim: "LocalizedHello"), Text(verbatim: "kvSwiftWebUI"))
    }


    @ViewBuilder
    private var localizationMenu: some View {
        Bundle.module.localizations
            .sorted()
            .lazy.compactMap { languageTag -> Text? in
                guard let url = URL(string: "/?\(KvHttpBundle.Constants.languageTagsUrlQueryItemName)=\(languageTag)") else { return nil }

                let locale = Locale(identifier: languageTag)
                let languageTagLabel = Text("`\(languageTag)`")

                var label = locale.localizedString(forIdentifier: languageTag)
                    .map { languageTagLabel + Text(verbatim: " — \($0)") }
                ?? languageTagLabel

                label = label.link(url)

                if languageTag != localization.languageTag,
                   let help = localization.locale.localizedString(forIdentifier: languageTag)
                {
                    /// `.help(_:)` modifier provides contextual help information usually presented as a tooltip.
                    label = label.help(help)
                }

                return label
            }
            .reduce(Optional<Text>.none) { partialResult, text in
                switch partialResult {
                case .some(let partialResult):
                    partialResult + Text(verbatim: ", ") + text
                case .none:
                    text
                }
            }
    }

}
