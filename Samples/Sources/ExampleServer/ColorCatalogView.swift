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
//  ColorCatalogView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 09.01.2024.
//

import kvCssKit
import kvSwiftWebUI



struct ColorCatalogView : View {

    @Environment(\.navigationPath) private var navigationPath


    private struct Constants {

        static let cellCornerRadius: KvCssLength = 6
        static let cellSpacing: KvCssLength = 6

    }


    var body: some View {
        Page(title: Text("Color Catalog"),
             subtitle: Text("This page contains previews of some colors available in kvSwiftWebUI framework"),
             sourceFilePath: "ColorCatalogView.swift"
        ) {
            customColorSection

            ColorSection<StandardColorID>(header: Text("Standard Colors"))
            ColorSection<WebColorID>(header: Text("Web Colors"))
        }
        /// Navigation destinations are defined with `navigationDestination` modifier.
        /// This modifier can be called several times.
        /// The framework selects first destination the data value is successfully initialized for.
        ///
        /// In this example the types are string representable and initialized by an URL path component in the same order the navigation destinations are declared.
        .navigationDestination(for: StandardColorID.self, destination: ColorDetailView.init(colorID:))
        .navigationDestination(for: WebColorID.self, destination: ColorDetailView.init(colorID:))
        .navigationDestination(for: HexColorID.self, destination: ColorDetailView.init(colorID:))
    }


    private var customColorSection: some View {
        Section1(header: Text("Custom Colors")) {
            Text("""
                There are several ways to declare custom colors.
                The simplest one is to use HEX literals: `let color: Color = 0x2F4F4F`.
                """)

            Text("""
                Try to view a custom color page having \"#RRGGBB\" HEX representation at /\(navigationPath.urlPath.joined)/\(HexColorID.prefix)RRGGBB URL. \
                For example:
                """)

            do {
                let hexColorID = HexColorID(0x2F4F4F)

                NavigationLink(value: hexColorID) {
                    Text(verbatim: "/\(navigationPath.urlPath.joined)/\(hexColorID.rawValue)")
                }
            }

            Text("This is an example of dynamic navigation destinations.")
        }
    }


    // MARK: .ColorSection

    private struct ColorSection<ID : ColorID> : View
    where ID : CaseIterable, ID.AllCases : RandomAccessCollection
    {

        init(header: Text) {
            self.header = header
        }


        private let header: Text

        @Environment(\.horizontalSizeClass) private var horizontalSizeClass


        var body: some View {
            Section1(header: header) {
                Text("Colors below are available as static properties of `Color` type.")

                let (numberOfColumns, font): (Int, Font) = switch horizontalSizeClass {
                case .regular: (3, .system(.body, design: .monospaced))
                case .compact, .none: (2, .system(.caption, design: .monospaced))
                }

                let allCases = ID.allCases
                let numberOfRows = (allCases.count + numberOfColumns - 1) / numberOfColumns

                let cellWidth = (BlockConstants.regularContentWidth + Constants.cellSpacing) / numberOfColumns - Constants.cellSpacing

                Grid(horizontalSpacing: Constants.cellSpacing, verticalSpacing: Constants.cellSpacing) {
                    ForEach(0..<numberOfRows) { row in
                        GridRow {
                            ForEach(row * numberOfColumns ..< min(allCases.count, (row + 1) * numberOfColumns)) { offset in
                                let colorID = allCases[allCases.index(allCases.startIndex, offsetBy: offset)]
                                let color = colorID.color

                                NavigationLink(value: colorID) {
                                    Text(verbatim: colorID.label)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, .em(0.25))
                                        .frame(idealWidth: cellWidth, minHeight: .em(3))
                                        .padding(.vertical, .em(0.25))
                                }
                                .foregroundStyle(color.label)
                                .background(color)
                                .clipShape(.rect(cornerRadius: Constants.cellCornerRadius))
                            }
                        }
                    }
                }
                .font(font)
            }
        }

    }

}
