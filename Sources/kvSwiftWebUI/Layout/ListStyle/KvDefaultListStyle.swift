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
//  KvDefaultListStyle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 26.05.2024.
//

public typealias DefaultListStyle = KvDefaultListStyle



/// List style that describes the default behavior and appearance for a list.
///
/// - Note: Currently lists with the default style look like the vertical stacks.
public struct KvDefaultListStyle : KvListStyle {

    public static let shared = KvDefaultListStyle()

    static let sharedErased = shared.eraseToAnyListStyle()



    // MARK: : KvListStyle

    public func eraseToAnyListStyle() -> KvAnyListStyle {
        .init(listContainerBlock: { context, rowSpacing, innerFragmentBlock in
            /// Currently list with the default style is rendered just like a vertical stack.
            context.representation(
                containerAttributes: .stack(.vertical),
                htmlAttributes: .init {
                    $0.insert(classes: "flexV",
                              context.html.cssFlexClass(for: KvVerticalAlignment.top, as: .mainContent),
                              context.html.cssFlexClass(for: KvHorizontalAlignment.leading, as: .crossItems))
                    $0.append(styles: "row-gap:\((rowSpacing ?? 0).css)")
                }
            ) { context, htmlAttributes in
                let fragment = innerFragmentBlock(context)

                return .tag(.div, attributes: htmlAttributes ?? .empty, innerHTML: fragment)
            }
        })
    }

}



// MARK: - KvListStyle

extension KvListStyle where Self == KvDefaultListStyle {

    public static var automatic: KvDefaultListStyle { .shared }

}
