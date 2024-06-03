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
//  KvMarkedListStyle.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 25.05.2024.
//

public typealias MarkedListStyle = KvMarkedListStyle



/// List style that describes the behavior and appearance of a list where each item is prefixed with a marker.
/// See ``Marker`` type for available markers.
///
/// - SeeAlso: ``KvListStyle/marked``, ``KvListStyle/marked(_:)``.
public struct KvMarkedListStyle : KvListStyle {

    public static let automatic = KvMarkedListStyle(marker: .automatic)



    @usableFromInline
    let marker: Marker



    @inlinable
    public init(marker: Marker) {
        self.marker = marker
    }



    // MARK: : KvListStyle

    public func eraseToAnyListStyle() -> KvAnyListStyle {
        return .init(listContainerBlock: { context, rowSpacing, innerFragmentBlock in
            context.representation(
                htmlAttributes: .init {
                    $0.insert(optionalClasses: context.html.cssItemSpacingClass(rowSpacing ?? KvDefaults.htmlListSpacing))
                    if let listStyleTypes = marker.listStyleTypeCSS {
                        $0.append(styles: listStyleTypes.lazy.map { "list-style-type:\($0)" })
                    }
                }
            ) { context, htmlAttributes in
                let context = context.descendant(containerAttributes: .htmlList)
                let innerFragment = innerFragmentBlock(context)

                return .tag(
                    .ul,
                    attributes: htmlAttributes ?? .empty,
                    innerHTML: innerFragment
                )
            }
        })
    }



    // MARK: .Marker

    /// Enumeration of available markers.
    public enum Marker {

        /// Platform-dependent automatic marker. Usually, browsers use discs, circles and squares on different list levels.
        case automatic

        /// Associated string is used as a list item marker.
        case string(String)

        /// Hollow circles.
        case circle
        /// Filled circles.
        case disc
        /// Disclosure symbol. E.g. it's used in lists with collapsible items.
        case disclosure(state: DisclosureState)
        /// No markers.
        case none
        /// Filled squares.
        case square


        // MARK: .DisclosureState

        public enum DisclosureState {
            case closed, open
        }


        // MARK: CSS

        var listStyleTypeCSS: String? {
            switch self {
            case .automatic: nil
            case .circle: "circle"
            case .disc: "disc"
            case .disclosure(state: .closed): "disclosure-closed"
            case .disclosure(state: .open): "disclosure-open"
            case .none: "none"
            case .square: "square"
            case .string(let marker): "\"\(marker.replacingOccurrences(of: "\"", with: "\\\""))\""
            }
        }

    }

}



// MARK: - KvListStyle

extension KvListStyle where Self == KvMarkedListStyle {

    public static var marked: KvMarkedListStyle { .automatic }


    public static func marked(_ marker: KvMarkedListStyle.Marker) -> KvMarkedListStyle {
        .init(marker: marker)
    }

}
