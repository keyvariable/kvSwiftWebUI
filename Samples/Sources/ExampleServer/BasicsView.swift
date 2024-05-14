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
//  BasicsView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 30.10.2023.
//

import Foundation

import kvCssKit
import kvSwiftWebUI



/// A view containing small examples of working with views and view modifiers.
///
/// Note the way large and complex hierarchy of views is split to structures, methods and calculated properties.
struct BasicsView : View {

    var body: some View {
        Page(title: Text("The Basics"),
             subtitle: Text("Various examples of the basic functionality"),
             sourceFilePath: "BasicsView.swift"
        ) {
            appearanceSection
            layoutSection
            imageSection
            textSection
            environmentSection
            viewModifierSection
        }
        /// This modifier provides keyword metadata for the resulting navigation destination.
        /// If several views declare keyword metadata in a navigation destination then all the keywords are joined.
        ///
        /// - Note: Keywords are localized.
        ///
        /// - SeeAlso: `.metadata(description:)` modifier.
        ///
        /// - Tip: Use `Text(verbatim:)` to prevent localization of argument.
        .metadata(keywords: Text("basics"))
    }


    private var appearanceSection: some View {
        Section1(header: Text("Appearance")) {
            Section2(header: Text("Colors")) {
                Text("Coral on indigo")
                    .foregroundStyle(.coral)
                    .background(.indigo)
                Text("Lamp (yellow in dark, gray in light)")
                    .foregroundStyle(.light(0x777777, dark: 0xFFFF00))
                Text("White with custom opacity on HEX RGB")
                    .foregroundStyle(.white.opacity(0.65))
                    .background(Color(0xBE38F3))
            }

            Section2(header: Text("Gradients")) {
                let width: KvCssLength = 120
                let height: KvCssLength = 48

                ForEach([ LinearGradient.Anchor.trailing, .bottom, .bottomLeading ], id: \.self) {
                    LinearGradient(colors: [ .violet, .cyan, .indigo ], endPoint: $0)
                        .frame(width: width, height: height)
                }

                LinearGradient(gradient: .init(colors: [ .indigo, .cyan, .violet ]), axis: .angle(0.1 * .pi))
                    .frame(width: width, height: height)

                LinearGradient(stops: [ .init(color: .violet, location: 0.50),
                                        .init(color: .blue, location: 0.65),
                                        .init(color: .cyan, location: 0.65),
                                        .init(color: .indigo, location: 0.80) ],
                               endPoint: .trailing)
                .frame(width: width, height: height)
            }

            Section2(header: Text("Fonts")) {
                Text(".headline")
                    .font(.headline)
                Text(".system(size: 20, weight: .ultraLight)")
                    .font(.system(size: 20, weight: .ultraLight))
                Text(".system(.body, design: .monospaced)")
                    .font(.system(.body, design: .monospaced))
                Text(".custom(\"Jura\", fixedSize: 15)")
                    .font(.custom("Jura", fixedSize: 15))
            }

            Section2(header: Text("Clip Shapes")) {
                clipShapeTemplateView { Text("`RoundedRectangle`") }
                    .clipShape(.rect(cornerRadius: .em(0.6)))

                clipShapeTemplateView { Text("`RoundedRectangle`") }
                    .clipShape(.rect(cornerSize: .init(width: .em(1), height: .em(0.7))))

                clipShapeTemplateView { Text("`UnevenRoundedRectangle`") }
                    .clipShape(.rect(topLeadingRadius: .em(0.4), bottomLeadingRadius: .em(0.9), bottomTrailingRadius: .em(0.6), topTrailingRadius: .em(1.4)))

                clipShapeTemplateView { Text("`Ellipse`") }
                    .clipShape(.ellipse)
            }
        }
    }


    private func clipShapeTemplateView<Content : View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.footnote)
            .padding(.em(0.6))
            .background(.systemGray4)
    }


    private var layoutSection: some View {
        Section1(header: Text("Layout")) {
            Section2(header: Text("Frame and Padding")) {
                Text("`.padding(16).background(.systemGray4)`")
                    .font(.system(.caption, design: .monospaced))
                    .padding(16)
                    .background(.systemGray4)
                Text("`.background(.systemGray4).padding(16)`")
                    .font(.system(.caption, design: .monospaced))
                    .background(.systemGray4)
                    .padding(16)
                Text("Text")
                    .font(.system(.caption, design: .monospaced))
                    .padding(.horizontal, 16).padding(.vertical, 4)
                    .background(.coral)
                    .frame(width: 168)
                    .padding(4)
                    .background(.teal)
                    .frame(width: 256, height: 60, alignment: .trailing)
                    .padding(4)
                    .background(.systemGray4)
            }

            Section2(header: Text("HStack")) {
                ForEach([ VerticalAlignment.center, .top, .bottom, .firstTextBaseline, .lastTextBaseline ], id: \.self) {
                    HStackDemoView(alignment: $0)
                }
            }

            Section2(header: Text("ZStack")) {
                ZStack {
                    HStack {
                        Color.green
                            .frame(width: 48, height: 48)
                            .clipShape(.rect(cornerRadius: 8))

                        Color.blue
                            .frame(width: 48, height: 48)

                        Color.violet
                            .frame(width: 48, height: 48)
                            .clipShape(.ellipse)
                    }

                    HStack {
                        ForEach(0..<2) { _ in
                            Color.yellow
                                .frame(idealWidth: .percents(100), idealHeight: 8)
                        }
                    }
                    .padding()
                }
                /// This modifier provides text for a tooltip.
                .help("This view is made programmatically uzing ZStack")
            }

            Section2(header: Text("Grid")) {
                Grid {
                    GridRow {
                        ForEach(0..<3) { column in Text(verbatim: "(1, \(column))") }
                    }
                    GridRow(alignment: .top) {
                        Text("2/1")
                        Text("2/2")
                        Text("2\n3")
                        Text("2/4")
                    }
                    GridRow {
                        ForEach(0..<4) { _ in
                            Color.separator
                                .frame(maxWidth: .infinity, idealHeight: 4)
                        }
                    }
                    GridRow(alignment: .bottom) {
                        Text("<")
                            .gridColumnAlignment(.leading)
                        Text("===\nspan 2")
                            .multilineTextAlignment(.center)
                            .gridColumnAlignment(.center)
                            .gridCellColumns(2)
                        Text(">")
                            .gridColumnAlignment(.trailing)
                    }
                    Color.separator
                        .frame(maxWidth: .infinity, idealHeight: 6)
                    GridRow {
                        Color.clear
                        Text("Lorem")
                        Text("Ipsum")
                    }
                }
            }
        }
    }


    private var imageSection: some View {
        Section1(header: Text("Images")) {
            let tileSize: (width: KvCssLength, height: KvCssLength) = (256, 72)

            Section2(header: Text("Simple SVG Image")) {
                Image("img/circles.svg")
                    /// Image accessibility labels are used as values for *alt* HTML attribute. It matters for SEO and screen readers.
                    .accessibilityLabel("Example of an SVG image with colored circles on transparent background")
            }

            Section2(header: Text("Resizing")) {
                Preview(caption: Text("`.resizable()`")) {
                    Image("img/circles.svg")
                        .resizable()
                        .frame(width: tileSize.width, height: tileSize.height)
                }
                Preview(caption: Text("`.resizable(resizingMode: .tile)`")) {
                    Image("img/circles.svg")
                        .resizable(resizingMode: .tile)
                        .frame(width: tileSize.width, height: tileSize.height, alignment: .topLeading)
                }
            }

            Section2(header: Text("Template Redering Mode")) {
                Preview(caption: Text("current foreground style")) {
                    Image("img/circles.svg")
                        .renderingMode(.template)
                }
                Preview(caption: Text("`.foregroundStyle(.coral)`")) {
                    Image("img/circles.svg")
                        .renderingMode(.template)
                        .foregroundStyle(.coral)
                }
                Preview(caption: Text("`.foregroundStyle(.linearGradient(...))`")) {
                    Image("img/circles.svg")
                        .renderingMode(.template)
                        .foregroundStyle(.linearGradient(colors: [ .indigo, .violet ], endPoint: .trailing))
                }
                Preview(caption: Text("`.foregroundStyle(.linearGradient(...))`")) {
                    Image("img/circles.svg")
                        .resizable(resizingMode: .tile)
                        .renderingMode(.template)
                        .frame(width: tileSize.width + 12, height: tileSize.height - 16)
                        .foregroundStyle(.linearGradient(stops: [ .init(color: .indigo, location: 0.35), .init(color: .cyan, location: 0.5), .init(color: .violet, location: 0.65) ],
                                                         endPoint: .topTrailing))
                }
            }
        }
    }


    private var textSection: some View {
        Section1(header: Text("Texts")) {
            Section2(header: Text("Concatenation and Styling")) {
                Text("Example of ")
                + (Text("green ") + Text("semibold text").fontWeight(.semibold))
                    .foregroundStyle(.green)
                + Text(verbatim: " ")
                + (Text("of custom font ") + Text("with italics").italic())
                    .font(.custom("Jura", fixedSize: 18))
                + Text(verbatim: ".")

                Text("Caffeine")
                    .link(URL(string: "https://wikipedia.org/wiki/Caffeine")!)
                + Text(verbatim: ": ")
                + Text("C") + Text("8").subscript + Text("H") + Text("10").subscript + Text("N") + Text("4").subscript + Text("O") + Text("2").subscript

                Text("2") + (Text("3") + Text("2").superscript + Text("+1")).superscript + Text(" = 2") + Text("10").superscript + Text(" = 1024")

                Text("[Markdown](https://www.markdownguide.org): **bold**, *italic*, <sub>subscript</sub>, <sup>superscript</sup>, `source_code`.")
            }

            Section2(header: Text("Text Case")) {
                let example = Text("Lorem ipsum dolor sit amet").padding(.em(0.35))

                Preview(caption: Text("no modification")) { example }
                Preview(caption: Text("`.textCase(.uppercase)`")) { example.textCase(.uppercase) }
                Preview(caption: Text("`.textCase(.lowercase)`")) { example.textCase(.lowercase) }
            }

            Section2(header: Text("Interpolations")) {
                /// `KvLocalizedStringKey` supports string interpolations.
                Text("`Double.pi` is \(Double.pi) (\(Double.pi, format: "%.16g")).")
                /// `Text` can be passed to `KvLocalizedStringKey` string interpolations as an argument.
                /// It helps to avoid usage of hard-to-read concatenations and use better localization keys.
                /// In this case it's needed to provide translations for "This text" and "%@ is interpolated into another text." strings.
                let argument: Text = Text("This text")
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    /// `Text` interpolations support `.help(_:)` modifier.
                    .help("An interpolation argument")
                Text("\(argument) is interpolated into another text.")
            }
        }
    }


    private var environmentSection: some View {
        Section1(header: Text("Environment")) {
            HorizontalSizeClassSection()
        }
    }


    private var viewModifierSection: some View {
        Section1(header: Text("View Modifiers")) {
            Section2(header: Text("Adaptive Padding Sample")) {
                Text("Below are examples where the same `Text` view is modified with the same view modifier. This modifier applies large or small padding whether horizontal size class is regular.")

                HorizontalSizeClassPreview {
                    Text("Text")
                        .modifier(AdaptivePaddingViewModifier())
                }
            }
        }
    }



    // MARK: .Preview

    private struct Preview<Content : View> : View {

        let caption: Text
        let content: Content


        init(caption: Text, @ViewBuilder content: () -> Content) {
            self.caption = caption
            self.content = content()
        }


        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                caption
                    .font(.caption)
                content
                    .padding(.em(0.25))
                    .background(.systemGray4)
                    .clipShape(.rect(cornerRadius: .em(0.25)))
            }
        }

    }



    // MARK: .HorizontalSizeClassPreview

    /// This view presents the same content in previews in current horizontal size class and for each value.
    private struct HorizontalSizeClassPreview<Content : View> : View {

        let content: Content


        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }


        var body: some View {
            preview(sizeClass: nil)

            ForEach(UserInterfaceSizeClass.allCases, id: \.self) {
                preview(sizeClass: $0)
            }
        }


        @ViewBuilder
        private func preview(sizeClass: UserInterfaceSizeClass?) -> some View {
            let caption = Text("Size class: \(Text.md(verbatim: sizeClass.map { "`.\($0)`" } ?? "current"))")

            switch sizeClass {
            case .none:
                Preview(caption: caption) { content }
            case .some:
                Preview(caption: caption) {
                    content
                }
                .environment(\.horizontalSizeClass, sizeClass)
            }
        }

    }



    // MARK: .HStackDemoView

    private struct HStackDemoView : View {

        let alignment: VerticalAlignment


        // MARK: : View

        var body: some View {
            Preview(caption: Text.md(verbatim: "alignment: `.\(alignment)`")) {
                HStack(alignment: alignment) {
                    item(Text("Dog"))
                    item(Text("Dog\nDog"))
                    item(Text("Dog").font(.system(size: 32, weight: .ultraLight)))
                    item(Text("Dog\nDog\nDog"))
                }
            }
        }


        private func item<Content : View>(_ content: Content) -> some View {
            content
                .background(.systemGray2)
        }

    }



    // MARK: .HorizontalSizeClassSection

    private struct HorizontalSizeClassSection : View {

        var body: some View {
            Section2(header: Text.md(verbatim: "`\\.horizontalSizeClass`")) {
                Text("An adaptive view below is presented with adaptive and forced horizontal size classes. Note how stack direction, order of views, separator and font size are adapted for screen width.")

                HorizontalSizeClassPreview(content: ExampleView.init)
            }
        }


        // MARK: .ExampleView

        private struct ExampleView : View {

            @Environment(\.horizontalSizeClass) private var horizontalSizeClass


            var body: some View {
                switch horizontalSizeClass {
                case .regular:
                    HStack {
                        longText

                        separator
                            .frame(idealWidth: 2, maxHeight: .infinity)
                            .fixedSize(horizontal: true, vertical: false)

                        indicator
                    }
                    .padding(.em(0.35))

                case .compact, .none:
                    VStack {
                        indicator

                        separator
                            .frame(maxWidth: .infinity, idealHeight: 2)
                            .fixedSize(horizontal: false, vertical: true)

                        longText
                    }
                    .padding(.em(0.35))
                    .font(.system(size: 12))
                }
            }


            private var indicator: some View {
                Text("`\(horizontalSizeClass.map { ".\($0)" } ?? "nil")` horizontal size class")
            }

            private var separator: some View { Color.indigo.opacity(0.65) }

            private var longText: some View {
                Text(verbatim: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
            }

        }

    }



    // MARK: .AdaptivePaddingViewModifier

    /// This view modifier applies padding depending on current `\.horizontalSizeClass` value.
    private struct AdaptivePaddingViewModifier : ViewModifier {

        @Environment(\.horizontalSizeClass) private var horizontalSizeClass


        func body(content: Content) -> some View {
            content
                .padding(horizontalSizeClass == .regular ? .em(2) : .px(4))
        }

    }

}
