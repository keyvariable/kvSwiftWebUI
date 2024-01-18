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
//  ColorDetailView.swift
//  Samples-kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 09.01.2024.
//

import kvSwiftWebUI



protocol ColorID : RawRepresentable, Identifiable where RawValue == String {

    var color: Color { get }

    var label: String { get }

    var code: (scope: String?, expression: String, cast: String?) { get }

}


extension ColorID {

    var id: String { rawValue }

}



protocol StaticColorID : ColorID { }


extension StaticColorID {

    var label: String {
        /// Insertion of zero-width spaces before uppercase letters to provide sugested line breaks.
        ///
        /// - Note: This implementation is not optimal but short. Don't use it in production.
        "." + rawValue.replacing(#/([\p{Lu}\p{Lt}])/#, with: { match in "\u{200B}\(rawValue[match.range])" })
    }

    var code: (scope: String?, expression: String, cast: String?) {
        (scope: "Color", expression: label, cast: nil)
    }

}



struct ColorDetailView<ID : ColorID> : View {

    let colorID: ID


    var body: some View {
        let color = colorID.color
        let labelColor = color.label

        VStack {
            NavigationPathView()
                .font(.footnote)
                .foregroundStyle(labelColor.secondary)

            SourceLink(to: "ColorDetailView.swift")
                .font(.footnote)
                .foregroundStyle(labelColor.tertiary)

            let code = colorID.code

            let scope = secondaryCode(code.scope.map { "\($0)\n" }, color: labelColor)
            let cast = secondaryCode(code.cast.map { "\n\($0)" }, color: labelColor)
            let expression: Text = Text(verbatim: code.expression)
                .font(.system(.largeTitle, design: .monospaced))

            (scope + expression + cast)
            .multilineTextAlignment(.leading)
            .padding(.vertical, .em(4))
        }
        .foregroundStyle(labelColor)
        .padding(.em(1))
        .background(color)
        .navigationTitle(colorID.label)
    }


    private func secondaryCode(_ string: String?, color: Color) -> Text {
        guard let string else { return .init() }
        
        return Text(verbatim: string)
            .font(.system(.title, design: .monospaced))
            .foregroundStyle(color.secondary)
    }

}



// MARK: HexColorID

/// - Note: This type doesn't conform to `CaseIterable`. Navigation destinations for such types are sythesized lazily.
struct HexColorID : ColorID, RawRepresentable {

    let hexCode: UInt


    init(_ hexCode: UInt) {
        self.hexCode = hexCode
    }


    // MARK: : RawRepresentable

    var rawValue: String { String(format: "\(HexColorID.prefix)%06X", hexCode) }


    init?(rawValue: String) {
        guard rawValue.hasPrefix(HexColorID.prefix) else { return nil }

        let rawCode = rawValue.dropFirst(HexColorID.prefix.count)

        guard rawCode.count == 6,
              let hexCode = UInt(rawCode, radix: 16)
        else { return nil }

        self.hexCode = hexCode
    }


    static var prefix: String { "hex-" }


    // MARK: : ColorID

    var label: String { String(format: "0x%06X", hexCode) }

    var color: Color { .init(hex: hexCode) }

    var code: (scope: String?, expression: String, cast: String?) {
        (scope: nil, expression: label, cast: "as Color")
    }

}



// MARK: StandardColorID

/// - Note: Conformance to `CaseIterable` protocol makes navigation destinations for such types to be presynthesized and optimized.
///     They are served faster and share some resources.
enum StandardColorID : String, StaticColorID, CaseIterable {

    case black
    case blue
    case brown
    case cyan
    case gray
    case green
    case indigo
    case mint
    case orange
    case pink
    case purple
    case red
    case teal
    case white
    case yellow


    var color: Color {
        switch self {
        case .black: .black
        case .blue: .blue
        case .brown: .brown
        case .cyan: .cyan
        case .gray: .gray
        case .green: .green
        case .indigo: .indigo
        case .mint: .mint
        case .orange: .orange
        case .pink: .pink
        case .purple: .purple
        case .red: .red
        case .teal: .teal
        case .white: .white
        case .yellow: .yellow
        }
    }

}



// MARK: WebColorID

enum WebColorID : String, StaticColorID, CaseIterable {

    case aliceBlue
    case antiqueWhite
    case aqua
    case aquamarine
    case azure
    case beige
    case bisque
    case blanchedAlmond
    case blueViolet
    case burlyWood
    case cadetBlue
    case chartreuse
    case chocolate
    case coral
    case cornflowerBlue
    case cornsilk
    case crimson
    case darkBlue
    case darkCyan
    case darkGoldenrod
    case darkGreen
    case darkKhaki
    case darkMagenta
    case darkOliveGreen
    case darkOrange
    case darkOrchid
    case darkRed
    case darkSalmon
    case darkSeaGreen
    case darkSlateBlue
    case darkSlateGray
    case darkTurquoise
    case darkViolet
    case deepPink
    case deepSkyBlue
    case dimGray
    case dodgerBlue
    case firebrick
    case floralWhite
    case forestGreen
    case fuchsia
    case gainsboro
    case ghostWhite
    case gold
    case goldenrod
    case greenYellow
    case honeydew
    case hotPink
    case indianRed
    case ivory
    case khaki
    case lavender
    case lavenderBlush
    case lawnGreen
    case lemonChiffon
    case lightBlue
    case lightCoral
    case lightCyan
    case lightGoldenrodYellow
    case lightGray
    case lightGreen
    case lightPink
    case lightSalmon
    case lightSeaGreen
    case lightSkyBlue
    case lightSlateGray
    case lightSteelBlue
    case lightYellow
    case lime
    case limeGreen
    case linen
    case magenta
    case maroon
    case mediumAquamarine
    case mediumBlue
    case mediumOrchid
    case mediumPurple
    case mediumSeaGreen
    case mediumSlateBlue
    case mediumSpringGreen
    case mediumTurquoise
    case mediumVioletRed
    case midnightBlue
    case mintCream
    case mistyRose
    case moccasin
    case navajoWhite
    case navy
    case oldLace
    case olive
    case oliveDrab
    case orangeRed
    case orchid
    case paleGoldenrod
    case paleGreen
    case paleTurquoise
    case paleVioletRed
    case papayaWhip
    case peachPuff
    case peru
    case plum
    case powderBlue
    case rebeccaPurple
    case rosyBrown
    case royalBlue
    case saddleBrown
    case salmon
    case sandyBrown
    case seaGreen
    case seashell
    case sienna
    case silver
    case skyBlue
    case slateBlue
    case slateGray
    case snow
    case springGreen
    case steelBlue
    case tan
    case thistle
    case tomato
    case turquoise
    case violet
    case wheat
    case whiteSmoke
    case yellowGreen


    var color: Color {
        switch self {
        case .aliceBlue: .aliceBlue
        case .antiqueWhite: .antiqueWhite
        case .aqua: .aqua
        case .aquamarine: .aquamarine
        case .azure: .azure
        case .beige: .beige
        case .bisque: .bisque
        case .blanchedAlmond: .blanchedAlmond
        case .blueViolet: .blueViolet
        case .burlyWood: .burlyWood
        case .cadetBlue: .cadetBlue
        case .chartreuse: .chartreuse
        case .chocolate: .chocolate
        case .coral: .coral
        case .cornflowerBlue: .cornflowerBlue
        case .cornsilk: .cornsilk
        case .crimson: .crimson
        case .darkBlue: .darkBlue
        case .darkCyan: .darkCyan
        case .darkGoldenrod: .darkGoldenrod
        case .darkGreen: .darkGreen
        case .darkKhaki: .darkKhaki
        case .darkMagenta: .darkMagenta
        case .darkOliveGreen: .darkOliveGreen
        case .darkOrange: .darkOrange
        case .darkOrchid: .darkOrchid
        case .darkRed: .darkRed
        case .darkSalmon: .darkSalmon
        case .darkSeaGreen: .darkSeaGreen
        case .darkSlateBlue: .darkSlateBlue
        case .darkSlateGray: .darkSlateGray
        case .darkTurquoise: .darkTurquoise
        case .darkViolet: .darkViolet
        case .deepPink: .deepPink
        case .deepSkyBlue: .deepSkyBlue
        case .dimGray: .dimGray
        case .dodgerBlue: .dodgerBlue
        case .firebrick: .firebrick
        case .floralWhite: .floralWhite
        case .forestGreen: .forestGreen
        case .fuchsia: .fuchsia
        case .gainsboro: .gainsboro
        case .ghostWhite: .ghostWhite
        case .gold: .gold
        case .goldenrod: .goldenrod
        case .greenYellow: .greenYellow
        case .honeydew: .honeydew
        case .hotPink: .hotPink
        case .indianRed: .indianRed
        case .ivory: .ivory
        case .khaki: .khaki
        case .lavender: .lavender
        case .lavenderBlush: .lavenderBlush
        case .lawnGreen: .lawnGreen
        case .lemonChiffon: .lemonChiffon
        case .lightBlue: .lightBlue
        case .lightCoral: .lightCoral
        case .lightCyan: .lightCyan
        case .lightGoldenrodYellow: .lightGoldenrodYellow
        case .lightGray: .lightGray
        case .lightGreen: .lightGreen
        case .lightPink: .lightPink
        case .lightSalmon: .lightSalmon
        case .lightSeaGreen: .lightSeaGreen
        case .lightSkyBlue: .lightSkyBlue
        case .lightSlateGray: .lightSlateGray
        case .lightSteelBlue: .lightSteelBlue
        case .lightYellow: .lightYellow
        case .lime: .lime
        case .limeGreen: .limeGreen
        case .linen: .linen
        case .magenta: .magenta
        case .maroon: .maroon
        case .mediumAquamarine: .mediumAquamarine
        case .mediumBlue: .mediumBlue
        case .mediumOrchid: .mediumOrchid
        case .mediumPurple: .mediumPurple
        case .mediumSeaGreen: .mediumSeaGreen
        case .mediumSlateBlue: .mediumSlateBlue
        case .mediumSpringGreen: .mediumSpringGreen
        case .mediumTurquoise: .mediumTurquoise
        case .mediumVioletRed: .mediumVioletRed
        case .midnightBlue: .midnightBlue
        case .mintCream: .mintCream
        case .mistyRose: .mistyRose
        case .moccasin: .moccasin
        case .navajoWhite: .navajoWhite
        case .navy: .navy
        case .oldLace: .oldLace
        case .olive: .olive
        case .oliveDrab: .oliveDrab
        case .orangeRed: .orangeRed
        case .orchid: .orchid
        case .paleGoldenrod: .paleGoldenrod
        case .paleGreen: .paleGreen
        case .paleTurquoise: .paleTurquoise
        case .paleVioletRed: .paleVioletRed
        case .papayaWhip: .papayaWhip
        case .peachPuff: .peachPuff
        case .peru: .peru
        case .plum: .plum
        case .powderBlue: .powderBlue
        case .rebeccaPurple: .rebeccaPurple
        case .rosyBrown: .rosyBrown
        case .royalBlue: .royalBlue
        case .saddleBrown: .saddleBrown
        case .salmon: .salmon
        case .sandyBrown: .sandyBrown
        case .seaGreen: .seaGreen
        case .seashell: .seashell
        case .sienna: .sienna
        case .silver: .silver
        case .skyBlue: .skyBlue
        case .slateBlue: .slateBlue
        case .slateGray: .slateGray
        case .snow: .snow
        case .springGreen: .springGreen
        case .steelBlue: .steelBlue
        case .tan: .tan
        case .thistle: .thistle
        case .tomato: .tomato
        case .turquoise: .turquoise
        case .violet: .violet
        case .wheat: .wheat
        case .whiteSmoke: .whiteSmoke
        case .yellowGreen: .yellowGreen
        }
    }

}
