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
//  KvText.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.10.2023.
//

import Foundation



public typealias Text = KvText



// TODO: DOC
public struct KvText : Equatable {

    @usableFromInline
    private(set) var content: Content

    @usableFromInline
    private(set) var attributes: Attributes?



    @usableFromInline
    init(content: Content, attributes: Attributes? = nil) {
        self.content = content
        self.attributes = attributes
    }


    // TODO: DOC
    @inlinable
    public init() { content = "" }


    // TODO: DOC
    @inlinable
    public init(verbatim content: String) {
        self.content = .string(content)
    }


    // TODO: DOC
    @inlinable
    public init<S>(_ content: S) where S : StringProtocol {
        self.content = .string(String(content))
    }


    // TODO: DOC
    @inlinable
    public init(_ key: KvLocalizedStringKey, tableName: String? = nil, bundle: Bundle? = nil, comment: StaticString? = nil) {
        self.init(verbatim: (bundle ?? .main).localizedString(forKey: key.content, value: nil, table: tableName))
    }



    // MARK: .Content

    @usableFromInline
    indirect enum Content : Equatable, ExpressibleByStringLiteral {

        case joined(KvText, KvText)
        case string(String)
        /// It can be used, when attributes of a text can't be merged with the assocuated child text. E.g. superscript inside subscript.
        case text(KvText)


        // MARK: : ExpressibleByStringLiteral

        @usableFromInline
        init(stringLiteral value: StringLiteralType) {
            self = .string(value)
        }


        // MARK: Operations

        @usableFromInline
        var isEmpty: Bool {
            switch self {
            case .joined(let lhs, let rhs): lhs.isEmpty && rhs.isEmpty
            case .string(let string): string.isEmpty
            case .text(let text): text.isEmpty
            }
        }


        // MARK: Operators

        @usableFromInline
        static func +(lhs: Self, rhs: Self) -> Self {
            guard !rhs.isEmpty else { return lhs }
            guard !lhs.isEmpty else { return rhs }
            

            /// - Returns: A content string when *text* is a string with no attributes.
            func PlainString(_ text: Text) -> String? {
                guard text.attributes?.isEmpty != false,
                      case .string(let string) = text.content
                else { return nil }

                return string
            }


            switch (lhs, rhs) {
            case (.string(let lstring), .string(let rstring)):
                return .string(lstring + rstring)

            case (.string(let lstring), .text(let rtext)):
                guard let rstring = PlainString(rtext) else { break }
                return .string(lstring + rstring)

            case (.text(let ltext), .string(let rstring)):
                guard let lstring = PlainString(ltext) else { break }
                return .string(lstring + rstring)

            case (.text(let ltext), .text(let rtext)):
                let text = ltext + rtext
                return text.attributes?.isEmpty != false ? text.content : .text(text)

            case (.string(let lstring), .joined(let mtext, let rtext)):
                guard let mstring = PlainString(mtext) else { break }
                return .joined(.init(content: .string(lstring + mstring)), rtext)

            case (.joined(let ltext, let mtext), .string(let rstring)):
                guard let mstring = PlainString(mtext) else { break }
                return .joined(ltext, .init(content: .string(mstring + rstring)))

            case (.text, .joined), (.joined, .text), (.joined, .joined):
                break
            }

            return .joined(.init(content: lhs), .init(content: rhs))
        }

    }



    // MARK: .Attributes

    @usableFromInline
    struct Attributes : Equatable {

        @usableFromInline
        static let empty: Self = .init()


        @usableFromInline
        var font: KvFont?

        @usableFromInline
        var fontWeight: KvFont.Weight?

        @usableFromInline
        var isItalic: Bool

        @usableFromInline
        var characterStyle: CharacterStyle?

        @usableFromInline
        var foregroundStyle: KvColor?

        /// - Note: It's not an `URL` due to the errors with `borrowing` keyword in come cases.
        @usableFromInline
        var linkURI: String?


        @usableFromInline
        init(font: KvFont? = nil, 
             fontWeight: KvFont.Weight? = nil,
             isItalic: Bool = false,
             characterStyle: CharacterStyle? = nil,
             foregroundStyle: KvColor? = nil,
             linkURI: String? = nil
        ) {
            self.font = font
            self.fontWeight = fontWeight
            self.isItalic = isItalic
            self.characterStyle = characterStyle
            self.foregroundStyle = foregroundStyle
            self.linkURI = linkURI
        }


        // MARK: .CharacterStyle

        @usableFromInline
        enum CharacterStyle {
            case `subscript`, superscript
        }


        // MARK: Operations

        @usableFromInline
        var isEmpty: Bool { self == .empty }



        func cssAttributes(in context: borrowing KvHtmlContext) -> KvHtmlKit.CssAttributes? {
            let cssAttributes = KvHtmlKit.CssAttributes(
                styles: font?.cssStyle(in: context),
                fontWeight.map { "font-weight:\($0.cssValue)" },
                isItalic ? "font-style:italic" : nil,
                (foregroundStyle?.cssExpression(in: context)).map { .joined("color:", $0) }
            )

            guard !cssAttributes.isEmpty else { return nil }
            return cssAttributes
        }


        /// - Returns: Given bytes wrapped by tags providing applicatino of some attributes of the receiver.
        func wrapping(_ innerBytes: consuming KvHtmlBytes) -> KvHtmlBytes {
            var bytes = innerBytes

            if let linkURI {
                bytes = .tag(.a, attributes: .href(URL(string: linkURI)!), innerHTML: bytes)
            }
            if let characterStyle {
                let tag: KvHtmlKit.Tag = switch characterStyle {
                case .subscript: .sub
                case .superscript: .sup
                }

                bytes = .tag(tag, innerHTML: bytes)
            }

            return bytes
        }

    }



    // MARK: .Case

    // TODO: DOC
    public enum Case : Hashable {

        // TODO: DOC
        case uppercase
        // TODO: DOC
        case lowercase


        // MARK: CSS

        var cssTextTransform: String {
            switch self {
            case .lowercase: "lowercase"
            case .uppercase: "uppercase"
            }
        }

    }



    // MARK: Operations

    @inlinable
    public var isEmpty: Bool { content.isEmpty }


    /// - Returns: The receiver's content without attributes as *KvHtmlBytes*.
    @usableFromInline
    var escapedPlainBytes: KvHtmlBytes {
        switch content {
        case .joined(let lhs, let rhs): .joined(lhs.escapedPlainBytes, rhs.escapedPlainBytes)
        case .string(let string): KvHtmlKit.Escaping.innerText(string)
        case .text(let text): text.escapedPlainBytes
        }
    }


    /// - Returns: A copy where attributes are reset.
    @usableFromInline
    consuming func dropAttributes() -> KvText {
        var copy = self
        copy.attributes = nil
        return copy
    }


    /// - Parameter block: The argument is always non-nil.
    @usableFromInline
    consuming func withModifiedAttributes(_ block: (inout Attributes?) -> Void) -> KvText {
        var copy = self

        if copy.attributes == nil {
            copy.attributes = .init()
        }

        block(&copy.attributes)

        return copy
    }



    // MARK: Modifiers

    // TODO: DOC
    @inlinable
    public consuming func font(_ font: Font?) -> KvText { withModifiedAttributes {
        $0!.font = font
    } }


    // TODO: DOC
    @inlinable
    public consuming func fontWeight(_ weight: KvFont.Weight?) -> KvText { withModifiedAttributes {
        $0!.fontWeight = weight
    } }


    // TODO: DOC
    @inlinable
    public consuming func foregroundStyle(_ style: KvColor?) -> KvText { withModifiedAttributes {
        $0!.foregroundStyle = style
    } }


    // TODO: DOC
    @inlinable
    public consuming func italic() -> KvText { italic(true) }


    // TODO: DOC
    @inlinable
    public consuming func italic(_ isActive: Bool) -> KvText { withModifiedAttributes {
        $0!.isItalic = isActive
    } }


    // TODO: DOC
    /// - Important: Consequent ``subscript`` and ``superscript`` modifiers ane nested.
    ///
    /// - SeeAlso: ``superscript``.
    @inlinable
    public var `subscript` : KvText { consuming get {
        switch attributes?.characterStyle {
        case .none:
            withModifiedAttributes { $0!.characterStyle = .subscript }
        case .some:
            KvText(content: .text(self), attributes: .init(characterStyle: .subscript))
        }
    } }


    // TODO: DOC
    /// - Important: Consequent ``subscript`` and ``superscript`` modifiers ane nested.
    ///
    /// - SeeAlso: ``subscript``.
    @inlinable
    public var superscript : KvText { consuming get {
        switch attributes?.characterStyle {
        case .none:
            withModifiedAttributes { $0!.characterStyle = .superscript }
        case .some:
            KvText(content: .text(self), attributes: .init(characterStyle: .superscript))
        }
    } }


    // TODO: DOC
    /// Consider ``KvLink`` view then link is entire text or arbitrary view.
    @inlinable
    public consuming func link(_ url: URL) -> KvText { withModifiedAttributes {
        $0!.linkURI = url.absoluteString
    } }



    // MARK: Operators

    @inlinable
    public static func +(lhs: consuming KvText, rhs: consuming KvText) -> KvText {
        let lhs = lhs, rhs = rhs

        guard !rhs.isEmpty else { return lhs }
        guard !lhs.isEmpty else { return rhs }

        // When both attributes are empty or equal.
        guard ((lhs.attributes?.isEmpty != false) && (rhs.attributes?.isEmpty != false))
                || lhs.attributes == rhs.attributes
        else { return KvText(content: .joined(lhs, rhs), attributes: nil) }

        return .init(content: lhs.content + rhs.content, attributes: lhs.attributes)
    }

}



// MARK: : KvView

extension KvText : KvView { public var body: KvNeverView { Body() } }



// MARK: : KvHtmlRenderable

extension KvText : KvHtmlRenderable {

    func renderHTML(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
        context.representation(cssAttributes: attributes?.cssAttributes(in: context.html)) { context, cssAttributes in

            func InnerHTML(_ text: KvText) -> KvHtmlBytes {
                let innerBytes: KvHtmlBytes = switch text.content {
                case .joined(let lhs, let rhs): .joined(InnerHTML(lhs), InnerHTML(rhs))
                case .string(let string): KvHtmlKit.Escaping.innerText(string)
                case .text(let text): InnerHTML(text)
                }

                return switch text.attributes {
                case .none: innerBytes
                case .some(let attributes): .tag(.span,
                                                 css: attributes.cssAttributes(in: context.html),
                                                 innerHTML: attributes.wrapping(innerBytes))
                }
            }


            let innerHTML: KvHtmlBytes = switch content {
            case .joined(let lhs, let rhs): .joined(InnerHTML(lhs), InnerHTML(rhs))
            case .string(let string): KvHtmlKit.Escaping.innerText(string)
            case .text(let text): InnerHTML(text)
            }

            let textStyle = context.environment?[\.font]?.textStyle ?? attributes?.font?.textStyle

            return .init(bytes: .tag(
                Self.tag(for: textStyle),
                css: cssAttributes,
                innerHTML: attributes?.wrapping(innerHTML) ?? innerHTML
            ))
        }
    }


    private static func tag(for textStyle: KvFont.TextStyle?) -> KvHtmlKit.Tag {
        switch textStyle {
        case .largeTitle: .h1
        case .title: .h2
        case .title2: .h3
        case .title3: .h4
        case .headline: .h5
        case .subheadline: .h6
        case .body: .p
        case .callout: .p
        case .caption: .p
        case .caption2: .p
        case .footnote: .p
        case .none: .p
        }
    }

}



// MARK: Auxiliary Constants

extension KvText {

    /// A space character. Is a shorthad for `Text(verbatim: " ")`.
    @inlinable
    public static var space: Self { .init(" ") }

    /// No-break space (NBSP).
    ///
    /// - SeeAlso: ``nnbsp``.
    @inlinable
    public static var nbsp: Self { .init("\u{A0}") }

    /// Narrow no-break space (NNBSP).
    ///
    /// - SeeAlso: ``nbsp``.
    @inlinable
    public static var nnbsp: Self { .init("\u{202F}") }

    /// Zero-width space (ZWSP).
    ///
    /// Useful as suggested line break in long words. For example it can be inserted between components in long URLs.
    @inlinable
    public static var zwsp: Self { .init("\u{200B}") }

}
