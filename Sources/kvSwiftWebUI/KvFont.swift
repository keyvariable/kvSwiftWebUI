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
//  KvFont.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 09.11.2023.
//

import Foundation

import kvCssKit



public typealias Font = KvFont



// TODO: DOC
public struct KvFont : Equatable {

    let family: Family
    let size: KvCssLength

    let textStyle: TextStyle

    @usableFromInline
    private(set) var weight: Weight

    @usableFromInline
    private(set) var options: Options = [ ]

    @usableFromInline
    private(set) var leading: Leading? = nil



    /// - Parameter size: `Nil` means `textStyle.size`.
    /// - Parameter weight: `Nil` means `textStyle.weight`.
    @usableFromInline
    init(family: Family, size: KvCssLength?, textStyle: TextStyle, weight: Weight?) {
        self.family = family
        self.size = size ?? textStyle.size
        self.textStyle = textStyle
        self.weight = weight ?? textStyle.weight
    }



    // MARK: .Family

    @usableFromInline
    enum Family : Equatable {
        case gFont(name: String)
        case resource(KvFontResource)
        case system(Design)
    }



    // MARK: .TextStyle

    public enum TextStyle : Hashable, CaseIterable {

        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case caption
        case caption2
        case footnote


        @usableFromInline
        var size: KvCssLength {
            switch self {
            case .largeTitle: .px(34)
            case .title: .px(25)
            case .title2: .px(22)
            case .title3: .px(20)
            case .headline: .px(17)
            case .subheadline: .px(15)
            case .body: .px(17)
            case .callout: .px(16)
            case .caption: .px(12)
            case .caption2: .px(11)
            case .footnote: .px(13)
            }
        }

        @usableFromInline
        var weight: Weight {
            switch self {
            case .largeTitle: .regular
            case .title: .regular
            case .title2: .regular
            case .title3: .regular
            case .headline: .semibold
            case .subheadline: .regular
            case .body: .regular
            case .callout: .regular
            case .caption: .regular
            case .caption2: .regular
            case .footnote: .regular
            }
        }

    }



    // MARK: .Weight

    public struct Weight : Hashable, Comparable {

        public static let black: Self = .init(cssValue: 900)
        public static let bold: Self = .init(cssValue: 700)
        public static let heavy: Self = .init(cssValue: 800)
        public static let light: Self = .init(cssValue: 300)
        public static let medium: Self = .init(cssValue: 500)
        public static let regular: Self = .init(cssValue: 400)
        public static let semibold: Self = .init(cssValue: 600)
        public static let thin: Self = .init(cssValue: 200)
        public static let ultraLight: Self = .init(cssValue: 100)


        @usableFromInline
        let cssValue: UInt16 /* 100...900 */


        // MARK: : Comparable

        @inlinable
        public static func <(lhs: Self, rhs: Self) -> Bool { lhs.cssValue < rhs.cssValue }

    }



    // MARK: .Design

    public enum Design : Hashable {
        case `default`
        case monospaced
        case rounded
        case serif
    }



    // MARK: .Leading

    // TODO: DOC
    public enum Leading : Hashable {

        case loose
        case standard
        case tight


        // MARK: CSS

        var cssLineHeight: String {
            switch self {
            case .loose: "1.9"
            case .standard: "normal"
            case .tight: "1.15"
            }
        }

    }



    // MARK: .Options

    @usableFromInline
    struct Options : OptionSet {

        @usableFromInline
        static let italic = Self(rawValue: 1 << 0)


        // MARK: : OptionSet

        @usableFromInline
        let rawValue: UInt

        @usableFromInline
        init(rawValue: UInt) { self.rawValue = rawValue }

    }



    // MARK: Fabrics

    // TODO: DOC
    public static let largeTitle: KvFont = .init(family: .system(.default), size: nil, textStyle: .largeTitle, weight: nil)

    // TODO: DOC
    public static let title: KvFont = .init(family: .system(.default), size: nil, textStyle: .title, weight: nil)

    // TODO: DOC
    public static let title2: KvFont = .init(family: .system(.default), size: nil, textStyle: .title2, weight: nil)

    // TODO: DOC
    public static let title3: KvFont = .init(family: .system(.default), size: nil, textStyle: .title3, weight: nil)

    // TODO: DOC
    public static let headline: KvFont = .init(family: .system(.default), size: nil, textStyle: .headline, weight: nil)

    // TODO: DOC
    public static let subheadline: KvFont = .init(family: .system(.default), size: nil, textStyle: .subheadline, weight: nil)

    // TODO: DOC
    public static let body: KvFont = .init(family: .system(.default), size: nil, textStyle: .body, weight: nil)

    // TODO: DOC
    public static let callout: KvFont = .init(family: .system(.default), size: nil, textStyle: .callout, weight: nil)

    // TODO: DOC
    public static let caption: KvFont = .init(family: .system(.default), size: nil, textStyle: .caption, weight: nil)

    // TODO: DOC
    public static let caption2: KvFont = .init(family: .system(.default), size: nil, textStyle: .caption2, weight: nil)

    // TODO: DOC
    public static let footnote: KvFont = .init(family: .system(.default), size: nil, textStyle: .footnote, weight: nil)


    // TODO: DOC
    @inlinable
    public static func system(_ style: TextStyle, design: Design? = nil, weight: Weight? = nil) -> KvFont {
        self.init(family: .system(design ?? .default), size: nil, textStyle: style, weight: weight)
    }


    // TODO: DOC
    @inlinable
    public static func system(size: KvCssLength, weight: Weight? = nil, design: Design? = nil) -> KvFont {
        self.init(family: .system(design ?? .default), size: size, textStyle: .body, weight: weight)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ name: String, fixedSize: KvCssLength) -> KvFont {
        self.init(family: .gFont(name: safeCustomFamilyName(name)), size: fixedSize, textStyle: .body, weight: nil)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ name: String, size: KvCssLength, relativeTo textStyle: Font.TextStyle) -> KvFont {
        self.init(family: .gFont(name: safeCustomFamilyName(name)), size: size, textStyle: textStyle, weight: nil)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ name: String, style: Font.TextStyle) -> KvFont {
        self.init(family: .gFont(name: safeCustomFamilyName(name)), size: nil, textStyle: style, weight: nil)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ name: String, size: KvCssLength) -> KvFont {
        custom(name, size: size, relativeTo: .body)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ resource: KvFontResource, fixedSize: KvCssLength) -> KvFont {
        .init(family: .resource(resource), size: fixedSize, textStyle: .body, weight: nil)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ resource: KvFontResource, size: KvCssLength, relativeTo textStyle: Font.TextStyle) -> KvFont {
        .init(family: .resource(resource), size: size, textStyle: textStyle, weight: nil)
    }


    // TODO: DOC
    @inlinable
    public static func custom(_ resource: KvFontResource, style: Font.TextStyle) -> KvFont {
        .init(family: .resource(resource), size: nil, textStyle: style, weight: nil)
    }



    // MARK: Modifiers

    @inline(__always)
    @usableFromInline
    consuming func modified(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }


    /// - Returns: A copy where weight is replaced with given value.
    @inlinable
    public consuming func weight(_ value: Weight) -> Self { modified {
        $0.weight = value
    } }


    /// - Returns: A copy where weight is ``Weight/bold``.
    ///
    /// - SeeAlso: ``weight(_:)``, ``italic()``.
    @inlinable
    public consuming func bold() -> Self { weight(.bold) }


    /// - Returns: A copy with italics.
    ///
    /// - SeeAlso: ``bold()``.
    @inlinable
    public consuming func italic() -> Self { modified {
        $0.options.insert(.italic)
    } }


    /// - Returns: A copy having given leading.
    @inlinable
    public consuming func leading(_ leading: Leading) -> Self { modified {
        $0.leading = leading
    } }



    // MARK: Operations

    var isItalic: Bool { options.contains(.italic) }


    @usableFromInline
    static func safeCustomFamilyName(_ unsafeFamilyName: String) -> String {
        unsafeFamilyName.filter {
            switch $0.asciiValue {
            case 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F,
                0x22/* "\"" */, 0x27/* "'" */:
                false
            default:
                true
            }
        }
    }


    /// - Returns: "font: ..."
    func cssStyle(in context: KvHtmlContext) -> String {
        "font:\(context.cssExpression(for: self))"
    }

}
