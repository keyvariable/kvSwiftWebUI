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
//  KvColor.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 02.11.2023.
//

import Foundation
import simd

import kvKit



public typealias Color = KvColor



// TODO: DOC
public struct KvColor : KvShapeStyle, Hashable, ExpressibleByIntegerLiteral {

    @usableFromInline
    var light: sRGB

    @usableFromInline
    var dark: sRGB?

    @usableFromInline
    var opacity: Double?



    /// Initializes a color.
    ///
    /// - Parameter dark: Optional dark theme value for adaptive colors.
    ///
    /// - Tip: Consider ``light(_:dark:opacity:)`` shorthand fabric for adaptive colors.
    @inlinable
    public init(_ light: sRGB, dark: sRGB? = nil, opacity: Double? = nil) {
        self.light = light
        self.dark = dark
        self.opacity = opacity
    }


    /// Initializes a constant color in HSB (HSV) color space.
    ///
    /// - Parameter hue: Value in 0..&lt;1 range mapped to 0°..&lt;360°.
    /// - Parameter saturation: Value in 0..&lt;1 range.
    /// - Parameter brightness: Value in 0..&lt;1 range.
    ///
    /// - Note: HSB and HSL are not the same.
    @inlinable
    public init(hue: Double, saturation: Double, brightness: Double, opacity: Double? = nil) {

        func F(_ n: Double) -> Double {
            let k = (n + 6.0 * hue).truncatingRemainder(dividingBy: 6.0)
            return brightness - brightness * saturation * (max(0.0, min(k, 4.0 - k, 1.0)) as Double)
        }

        self.init(.red(F(5), green: F(3), blue: F(1)), opacity: opacity)
    }


    // TODO: DOC: example of light and dark with .init(_:dark:opacity:).
    /// Initializes a constant grayscale color in sRGB color space.
    @inlinable
    public init(white: Double, opacity: Double? = nil) {
        self.init(.white(white), opacity: opacity)
    }


    // TODO: DOC: example of light and dark with .init(_:dark:opacity:).
    /// Initializes a constant color in sRGB color space.
    @inlinable
    public init(red: Double, green: Double, blue: Double, opacity: Double? = nil) {
        self.init(.red(red, green: green, blue: blue), opacity: opacity)
    }


    // TODO: DOC
    @inlinable
    public init<I : BinaryInteger>(hex: I, opacity: Double? = nil) {
        self.init(.init(hex: hex), opacity: opacity)
    }



    // MARK: : ExpressibleByIntegerLiteral

    /// Initializes SRGB color from integer in 0xRRGGBB format.
    @inlinable
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(hex: value)
    }



    // MARK: : KvShapeStyle

    public func eraseToAnyShapeStyle() -> KvAnyShapeStyle {
        .init(
            cssBackgroundStyle: { context, property in
                "\(property ?? "background-color"):\(cssBackgroundExpression(in: context))"
            },
            cssForegroundStyle: { context, property in
                "\(property ?? "color"):\(cssExpression(in: context))"
            },
            backgroundColor: { self },
            bottomBackgroundColor: { self }
        )
    }


    /// - Returns: Expression to be used as rvalue in CSS styles like `background: expr`.
    func cssBackgroundExpression(in context: borrowing KvHtmlContext) -> String {
        context.cssExpression(for: self)
    }



    // MARK: CSS

    /// - Returns: Expression to be used as rvalue in CSS styles like `color: expr`.
    func cssExpression(in context: KvHtmlContext) -> String {
        context.cssExpression(for: self)
    }



    // MARK: .sRGB

    // TODO: DOC: Expressible by HEX literal.
    public struct sRGB : Hashable, ExpressibleByIntegerLiteral {

        /// Red normalized component where 1.0 matches 255 integer component.
        public var red: Double
        /// Green normalized component where 1.0 matches 255 integer component.
        public var green: Double
        /// Blue normalized component where 1.0 matches 255 integer component.
        public var blue: Double
        /// Optional alpha component in range 0...1.
        public var alpha: Double?


        /// - Tip: Consider ``red(_:green:blue:alpha:)`` shorthand fabric.
        @inlinable
        public init(red: Double, green: Double, blue: Double, alpha: Double? = nil) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }

        /// - Parameter hex: An integer in 0xRRGGBB format.
        ///
        /// - Tip: Consider ``hex(_:alpha:)`` shorthand fabric and initialization from an integer literal..
        @inlinable
        public init<I : BinaryInteger>(hex: I, alpha: Double? = nil) {
            let mask: I = 0xFF
            let scale: Double = 1.0 / 255.0

            @inline(__always)
            func Normalized(shift: Int) -> Double { Double((hex >> shift) & mask) * scale }

            self.init(red: Normalized(shift: 16), green: Normalized(shift: 8), blue: Normalized(shift: 0), alpha: alpha)
        }


        @inlinable
        public static func red(_ red: Double, green: Double, blue: Double, alpha: Double? = nil) -> Self {
            .init(red: red, green: green, blue: blue, alpha: alpha)
        }

        @inlinable
        public static func white(_ white: Double, alpha: Double? = nil) -> Self {
            .init(red: white, green: white, blue: white, alpha: alpha)
        }

        /// - Parameter hex: An integer in 0xRRGGBB format.
        @inlinable
        public static func hex<I : BinaryInteger>(_ hex: I, alpha: Double? = nil) -> Self {
            .init(hex: hex, alpha: alpha)
        }


        // MARK: : ExpressibleByIntegerLiteral

        /// Initializes SRGB color from integer in 0xRRGGBB format.
        @inlinable
        public init(integerLiteral value: IntegerLiteralType) {
            self.init(hex: value)
        }


        // MARK: Operations

        /// - Returns: Luma value of sRGB (Rec. 709 primaries, [Wiki](https://wikipedia.org/wiki/HSL_and_HSV )).
        var luma709: Double { 0.2126 * red + 0.7152 * green + 0.0722 * blue }


        /// 8-bit clamped representation of the receiver.
        public var bytes: (red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8?) {

            func UInt8Component(_ component: Double) -> UInt8 {
                let clamped: Double = max(0.0 as Double, min(1.0 as Double, component))
                let scaled: Double = (clamped * 255.0).rounded()
                return UInt8(scaled)
            }

            return (red: UInt8Component(red), green: UInt8Component(green), blue: UInt8Component(blue), alpha.map(UInt8Component(_:)))
        }

        /// Hexadecimal representation of RGB components.
        public var hex: UInt32 {
            let bytes = self.bytes
            return (numericCast(bytes.red) as UInt32) << 16 | (numericCast(bytes.green) as UInt32) << 8 | (numericCast(bytes.blue) as UInt32)
        }

        /// Hexadecimal representation of RGB components as string.
        public var hexString: String { String(format: "%06X", hex) }

        /// Hexadecimal representation of RGBA components.
        ///
        /// - Note: Default alpha value is 1.0.
        public var hexRGBA: UInt32 {
            let bytes = self.bytes
            return ((numericCast(bytes.red) as UInt32) << 24
                    | (numericCast(bytes.green) as UInt32) << 16
                    | (numericCast(bytes.blue) as UInt32) << 8
                    | (numericCast(bytes.alpha ?? 0xFF) as UInt32))
        }

        /// Hexadecimal representation of RGB components as string.
        ///
        /// - Note: Default alpha value is 1.0.
        public var hexStringRGBA: String { String(format: "%08X", hexRGBA) }


        /// - Important: Color components of translucent colors are premultiplied by their `alpha` components.
        /// - Important: If *source* is equal to *destination* then *result* is ignored and 1.0 is returned.
        public static func inferOpacity(source: Self, destination: Self, result: Self) -> Double {
            typealias Math = KvMathDoubleScope
            typealias V3 = Math.Vector3

            func Premultiplied(_ color: Self) -> V3 {
                simd_double3(color.red, color.green, color.blue) * (color.alpha ?? 1.0)
            }

            let s = Premultiplied(source), r = Premultiplied(result)

            guard Math.isInequal(s, r, eps: 1e-3) else { return 1.0 }

            let d = Premultiplied(destination)

            let alpha = (((r - d) as V3) / ((s - d) as V3)).clamped(lowerBound: V3.zero, upperBound: V3.one)
            return alpha.sum() * (1.0 / 3.0) as Double
        }


        /// - Returns: The result of alpha blending of *source* over the receiver.
        @inlinable
        public func blend(_ source: Self) -> Self {
            guard let a = source.alpha,
                  abs(a - 1.0) >= 1e-3
            else { return source }

            return .init(red:   mix(self.red  , source.red  , t: a),
                         green: mix(self.green, source.green, t: a),
                         blue:  mix(self.blue , source.blue , t: a),
                         alpha: mix(self.alpha ?? 1.0, 1.0, t: a))
        }

    }



    // MARK: .Fabrics

    // TODO: DOC
    // TODO: DOC: Non-adaptive
    @inlinable
    public static func hex<I : BinaryInteger>(_ hex: I, opacity: Double? = nil) -> Self {
        .init(hex: hex, opacity: opacity)
    }


    // TODO: DOC: example
    /// - Returns: An adaptive color in sRGB color space with representations for light and dark environments.
    @inlinable
    public static func light(_ light: sRGB, dark: sRGB, opacity: Double? = nil) -> Self {
        .init(light, dark: dark, opacity: opacity)
    }



    // MARK: Modifiers

    @usableFromInline
    consuming func withModified(transform: (inout Self) -> Void) -> Self {
        var copy = self
        transform(&copy)
        return copy
    }


    /// - Returns: A copy where opacity is replaced with given value.
    @inlinable
    public consuming func opacity(_ value: Double) -> Self { withModified {
        $0.opacity = value
    } }


    /// - Returns: A second level of the receiver.
    @inlinable
    public var secondary: Self { consuming get { withModified {
        $0.opacity = ($0.opacity ?? 1.0) * 0.75
    } } }


    /// - Returns: A third level of the receiver.
    @inlinable
    public var tertiary: Self { consuming get { withModified {
        $0.opacity = ($0.opacity ?? 1.0) * 0.5
    } } }


    /// - Returns: A fourth level of the receiver.
    @inlinable
    public var quaternary: Self { consuming get { withModified {
        $0.opacity = ($0.opacity ?? 1.0) * 0.25
    } } }


    /// - Returns: A fifth level of the receiver.
    @inlinable
    public var quinary: Self { consuming get { withModified {
        $0.opacity = ($0.opacity ?? 1.0) * 0.125
    } } }



    // MARK: Auxiliaries

    // TODO: DOC
    /// It's designated to calculate dark shades when only light shades of origin color are available.
    ///
    /// - Returns: A copy of the receiver where `nil` dark variant is replaced with calculated value. Otherwise exact copy of the receiver is returned.
    public consuming func inferDark(origin: sRGB, lightBackground: sRGB = 0xFFFFFF, darkBackground: sRGB = 0x000000) -> Self {
        guard dark == nil else { return self }

        let opacity = sRGB.inferOpacity(source: origin, destination: lightBackground, result: light)
        let t = 1.0 - consume opacity

        let dark = sRGB(red:   light.red   - t * (lightBackground.red   - darkBackground.red  ),
                        green: light.green - t * (lightBackground.green - darkBackground.green),
                        blue:  light.blue  - t * (lightBackground.blue  - darkBackground.blue ),
                        alpha: light.alpha)

        return .light(light, dark: dark, opacity: self.opacity)
    }


    // TODO: DOC
    /// - Parameter origin: A color those light component is used as origin argument in ``inferDark(origin:lightBackground:darkBackground:)-9mejj``.
    @inlinable
    public consuming func inferDark(origin: Self, lightBackground: sRGB = 0xFFFFFF, darkBackground: sRGB = 0x000000) -> Self {
        inferDark(origin: origin.light, lightBackground: lightBackground, darkBackground: darkBackground)
    }


    /// - Returns: Light or dark variant of ``KvShapeStyle/label-swift.type.property`` color having greater difference in brightness with the receiver.
    ///
    /// - Note: If the receiver is an adaptive color then the result is adaptive too.
    public var label: Self {
        let label = Self.label

        let light = label.light
        let lightLuma = light.luma709

        let dark = label.dark ?? .white(1.0)
        let darkLuma = dark.luma709

        
        func SelectVariant(for background: sRGB) -> sRGB {
            let luma = background.luma709

            return abs(lightLuma - luma) >= abs(darkLuma - luma) ? light : dark
        }

        
        return .init(SelectVariant(for: self.light), dark: self.dark.map(SelectVariant(for:)), opacity: opacity)
    }

}



// MARK: : KvView

extension KvColor : KvView {

    public typealias Body = KvShapeStyleView

}



// MARK: KvShapeStyle Integration

extension KvShapeStyle where Self == KvColor {

    /// Adaptive transparent color.
    ///
    /// - Note: It is transparent white in light environment and transparent black in dark environment.
    @inlinable public static var clear: Self { .light(.hex(0xFFFFFF, alpha: 0), dark: .hex(0x000000, alpha: 0)) }


    @inlinable public static var black: Self { 0x000000 }

    // TODO: DOC: context-dependent color.
    @inlinable public static var blue: Self { .light(0x007AFF, dark: 0x0A84FF) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var brown: Self { .light(0xA2845E, dark: 0xAC8E68) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var cyan: Self { .light(0x55BEF0, dark: 0x5AC8F5) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var gray: Self { 0x8E8E93 }

    // TODO: DOC: context-dependent color.
    @inlinable public static var green: Self { .light(0x28CD41, dark: 0x32D74B) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var indigo: Self { .light(0x5856D6, dark: 0x5E5CE6) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var mint: Self { .light(0x00C7BE, dark: 0x63E6E2) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var orange: Self { .light(0xFF9500, dark: 0xFF9F0A) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var pink: Self { .light(0xFF2D55, dark: 0xFF375F) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var purple: Self { .light(0xAF52DE, dark: 0xBF5AF2) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var red: Self { .light(0xFF3B30, dark: 0xFF453A) }

    // TODO: DOC: context-dependent color.
    @inlinable public static var teal: Self { .light(0x59ADC4, dark: 0x6AC4DC) }
    
    @inlinable public static var white: Self { 0xFFFFFF }

    // TODO: DOC: context-dependent color.
    @inlinable public static var yellow: Self { .light(0xFFCC00, dark: 0xFFD60A) }


    // MARK: Web Colors

    @inlinable public static var aliceBlue: Self { 0xF0F8FF }
    @inlinable public static var antiqueWhite: Self { 0xFAEBD7 }
    @inlinable public static var aqua: Self { 0x00FFFF }
    @inlinable public static var aquamarine: Self { 0x7FFFD4 }
    @inlinable public static var azure: Self { 0xF0FFFF }
    @inlinable public static var beige: Self { 0xF5F5DC }
    @inlinable public static var bisque: Self { 0xFFE4C4 }
    @inlinable public static var blanchedAlmond: Self { 0xFFEBCD }
    @inlinable public static var blueViolet: Self { 0x8A2BE2 }
    @inlinable public static var burlyWood: Self { 0xDEB887 }
    @inlinable public static var cadetBlue: Self { 0x5F9EA0 }
    @inlinable public static var chartreuse: Self { 0x7FFF00 }
    @inlinable public static var chocolate: Self { 0xD2691E }
    @inlinable public static var coral: Self { 0xFF7F50 }
    @inlinable public static var cornflowerBlue: Self { 0x6495ED }
    @inlinable public static var cornsilk: Self { 0xFFF8DC }
    @inlinable public static var crimson: Self { 0xDC143C }
    @inlinable public static var darkBlue: Self { 0x00008B }
    @inlinable public static var darkCyan: Self { 0x008B8B }
    @inlinable public static var darkGoldenrod: Self { 0xB8860B }
    @inlinable public static var darkGreen: Self { 0x006400 }
    @inlinable public static var darkKhaki: Self { 0xBDB76B }
    @inlinable public static var darkMagenta: Self { 0x8B008B }
    @inlinable public static var darkOliveGreen: Self { 0x556B2F }
    @inlinable public static var darkOrange: Self { 0xFF8C00 }
    @inlinable public static var darkOrchid: Self { 0x9932CC }
    @inlinable public static var darkRed: Self { 0x8B0000 }
    @inlinable public static var darkSalmon: Self { 0xE9967A }
    @inlinable public static var darkSeaGreen: Self { 0x8FBC8F }
    @inlinable public static var darkSlateBlue: Self { 0x483D8B }
    @inlinable public static var darkSlateGray: Self { 0x2F4F4F }
    @inlinable public static var darkTurquoise: Self { 0x00CED1 }
    @inlinable public static var darkViolet: Self { 0x9400D3 }
    @inlinable public static var deepPink: Self { 0xFF1493 }
    @inlinable public static var deepSkyBlue: Self { 0x00BFFF }
    @inlinable public static var dimGray: Self { 0x696969 }
    @inlinable public static var dodgerBlue: Self { 0x1E90FF }
    @inlinable public static var firebrick: Self { 0xB22222 }
    @inlinable public static var floralWhite: Self { 0xFFFAF0 }
    @inlinable public static var forestGreen: Self { 0x228B22 }
    @inlinable public static var fuchsia: Self { 0xFF00FF }
    @inlinable public static var gainsboro: Self { 0xDCDCDC }
    @inlinable public static var ghostWhite: Self { 0xF8F8FF }
    @inlinable public static var gold: Self { 0xFFD700 }
    @inlinable public static var goldenrod: Self { 0xDAA520 }
    @inlinable public static var greenYellow: Self { 0xADFF2F }
    @inlinable public static var honeydew: Self { 0xF0FFF0 }
    @inlinable public static var hotPink: Self { 0xFF69B4 }
    @inlinable public static var indianRed: Self { 0xCD5C5C }
    @inlinable public static var ivory: Self { 0xFFFFF0 }
    @inlinable public static var khaki: Self { 0xF0E68C }
    @inlinable public static var lavender: Self { 0xE6E6FA }
    @inlinable public static var lavenderBlush: Self { 0xFFF0F5 }
    @inlinable public static var lawnGreen: Self { 0x7CFC00 }
    @inlinable public static var lemonChiffon: Self { 0xFFFACD }
    @inlinable public static var lightBlue: Self { 0xADD8E6 }
    @inlinable public static var lightCoral: Self { 0xF08080 }
    @inlinable public static var lightCyan: Self { 0xE0FFFF }
    @inlinable public static var lightGoldenrodYellow: Self { 0xFAFAD2 }
    @inlinable public static var lightGray: Self { 0xD3D3D3 }
    @inlinable public static var lightGreen: Self { 0x90EE90 }
    @inlinable public static var lightPink: Self { 0xFFB6C1 }
    @inlinable public static var lightSalmon: Self { 0xFFA07A }
    @inlinable public static var lightSeaGreen: Self { 0x20B2AA }
    @inlinable public static var lightSkyBlue: Self { 0x87CEFA }
    @inlinable public static var lightSlateGray: Self { 0x778899 }
    @inlinable public static var lightSteelBlue: Self { 0xB0C4DE }
    @inlinable public static var lightYellow: Self { 0xFFFFE0 }
    @inlinable public static var lime: Self { 0x00FF00 }
    @inlinable public static var limeGreen: Self { 0x32CD32 }
    @inlinable public static var linen: Self { 0xFAF0E6 }
    @inlinable public static var magenta: Self { 0xFF00FF }
    @inlinable public static var maroon: Self { 0x800000 }
    @inlinable public static var mediumAquamarine: Self { 0x66CDAA }
    @inlinable public static var mediumBlue: Self { 0x0000CD }
    @inlinable public static var mediumOrchid: Self { 0xBA55D3 }
    @inlinable public static var mediumPurple: Self { 0x9370DB }
    @inlinable public static var mediumSeaGreen: Self { 0x3CB371 }
    @inlinable public static var mediumSlateBlue: Self { 0x7B68EE }
    @inlinable public static var mediumSpringGreen: Self { 0x00FA9A }
    @inlinable public static var mediumTurquoise: Self { 0x48D1CC }
    @inlinable public static var mediumVioletRed: Self { 0xC71585 }
    @inlinable public static var midnightBlue: Self { 0x191970 }
    @inlinable public static var mintCream: Self { 0xF5FFFA }
    @inlinable public static var mistyRose: Self { 0xFFE4E1 }
    @inlinable public static var moccasin: Self { 0xFFE4B5 }
    @inlinable public static var navajoWhite: Self { 0xFFDEAD }
    @inlinable public static var navy: Self { 0x000080 }
    @inlinable public static var oldLace: Self { 0xFDF5E6 }
    @inlinable public static var olive: Self { 0x808000 }
    @inlinable public static var oliveDrab: Self { 0x6B8E23 }
    @inlinable public static var orangeRed: Self { 0xFF4500 }
    @inlinable public static var orchid: Self { 0xDA70D6 }
    @inlinable public static var paleGoldenrod: Self { 0xEEE8AA }
    @inlinable public static var paleGreen: Self { 0x98FB98 }
    @inlinable public static var paleTurquoise: Self { 0xAFEEEE }
    @inlinable public static var paleVioletRed: Self { 0xDB7093 }
    @inlinable public static var papayaWhip: Self { 0xFFEFD5 }
    @inlinable public static var peachPuff: Self { 0xFFDAB9 }
    @inlinable public static var peru: Self { 0xCD853F }
    @inlinable public static var plum: Self { 0xDDA0DD }
    @inlinable public static var powderBlue: Self { 0xB0E0E6 }
    @inlinable public static var rebeccaPurple: Self { 0x663399 }
    @inlinable public static var rosyBrown: Self { 0xBC8F8F }
    @inlinable public static var royalBlue: Self { 0x4169E1 }
    @inlinable public static var saddleBrown: Self { 0x8B4513 }
    @inlinable public static var salmon: Self { 0xFA8072 }
    @inlinable public static var sandyBrown: Self { 0xF4A460 }
    @inlinable public static var seaGreen: Self { 0x2E8B57 }
    @inlinable public static var seashell: Self { 0xFFF5EE }
    @inlinable public static var sienna: Self { 0xA0522D }
    @inlinable public static var silver: Self { 0xC0C0C0 }
    @inlinable public static var skyBlue: Self { 0x87CEEB }
    @inlinable public static var slateBlue: Self { 0x6A5ACD }
    @inlinable public static var slateGray: Self { 0x708090 }
    @inlinable public static var snow: Self { 0xFFFAFA }
    @inlinable public static var springGreen: Self { 0x00FF7F }
    @inlinable public static var steelBlue: Self { 0x4682B4 }
    @inlinable public static var tan: Self { 0xD2B48C }
    @inlinable public static var thistle: Self { 0xD8BFD8 }
    @inlinable public static var tomato: Self { 0xFF6347 }
    @inlinable public static var turquoise: Self { 0x40E0D0 }
    @inlinable public static var violet: Self { 0xEE82EE }
    @inlinable public static var wheat: Self { 0xF5DEB3 }
    @inlinable public static var whiteSmoke: Self { 0xF5F5F5 }
    @inlinable public static var yellowGreen: Self { 0x9ACD32 }


    // MARK: Non-standard Colors

    @inlinable public static var darkGray: Self { 0x555555 }

    @inlinable public static var systemGray2: Self { .light(0xAEAEB2, dark: 0x636366) }
    @inlinable public static var systemGray3: Self { .light(0xC7C7CC, dark: 0x48484A) }
    @inlinable public static var systemGray4: Self { .light(0xD1D1D6, dark: 0x3A3A3C) }
    @inlinable public static var systemGray5: Self { .light(0xE5E5EA, dark: 0x2C2C2E) }
    @inlinable public static var systemGray6: Self { .light(0xF2F2F7, dark: 0x1C1C1E) }

    @inlinable public static var label: Self { .light(0x000000, dark: 0xFFFFFF, opacity: 0.85) }
    @inlinable public static var textColor: Self { .light(0x000000, dark: 0xFFFFFF) }
    @inlinable public static var placeholderText: Self { .light(0x000000, dark: 0xFFFFFF, opacity: 0.25) }
    @inlinable public static var link: Self { .light(0x0068DA, dark: 0x419CFF) }
    @inlinable public static var opaqueSeparator: Self { .light(0xC6C6C8, dark: 0x38383A) }
    @inlinable public static var separator: Self { .light(.hex(0x3C3C43, alpha: 0.3), dark: .hex(0x545458, alpha: 0.6)) }
    @inlinable public static var grid: Self { .light(0xE6E6E6, dark: 0x1A1A1A) }
    @inlinable public static var headerText: Self { .light(.hex(0x000000, alpha: 0.85), dark: 0xFFFFFF) }
    @inlinable public static var alternatingContentBackground0: Self { .light(0xFFFFFF, dark: 0x1E1E1E) }
    @inlinable public static var alternatingContentBackground1: Self { .light(0xF4F5F5, dark: 0x0C0C0C) }
    @inlinable public static var shadow: Self { .light(0x000000, dark: 0x000000) }
    @inlinable public static var systemBackground: Self { .light(0xFFFFFF, dark: 0x000000) }
    @inlinable public static var secondarySystemBackground: Self { .light(0xF2F2F7, dark: 0x1C1C1E) }
    @inlinable public static var tertiarySystemBackground: Self { .light(0xFFFFFF, dark: 0x2C2C2E) }
    @inlinable public static var systemGroupedBackground: Self { .light(0xF2F2F7, dark: 0x000000) }
    @inlinable public static var secondarySystemGroupedBackground: Self { .light(0xFFFFFF, dark: 0x1C1C1E) }
    @inlinable public static var tertiarySystemGroupedBackground: Self { .light(0xF2F2F7, dark: 0x2C2C2E) }

}
