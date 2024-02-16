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
    private(set) var attributes: Attributes



    @usableFromInline
    init(content: Content, attributes: Attributes = .empty) {
        self.content = content
        self.attributes = attributes
    }


    // TODO: DOC
    @inlinable
    public init() { self.init(content: "") }


    // TODO: DOC
    @inlinable
    public init(verbatim content: String) {
        self.init(content: .verbatim(content))
    }


    // TODO: DOC
    @inlinable
    public init<S>(_ content: S) where S : StringProtocol {
        self.init(content: .localizable(.init(key: String(content))))
    }


    // TODO: DOC
    @inlinable
    public init(_ key: KvLocalizedStringKey, tableName: String? = nil, bundle: Bundle? = nil, comment: StaticString? = nil) {
        self.init(content: .localizable(.init(key: key.content, table: tableName, bundle: bundle)))
    }


    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    // TODO: DOC
    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    @inlinable
    public init(_ resource: LocalizedStringResource) {
        self.init(verbatim: String(localized: resource))
    }
    #endif // os(macOS) || os(iOS) || os(tvOS) || os(watchOS)



    // MARK: .Content

    @usableFromInline
    enum Content : Equatable, ExpressibleByStringLiteral {

        /// - Note: Block is used to reduce size of `Content` instances.
        case joined(() -> (KvText, KvText))

        case localizable(KvLocalization.StringResource)

        /// It can be used, when attributes of a text can't be merged with the associated child text. E.g. superscript inside subscript.
        ///
        /// - Note: Block is used to reduce size of `Content` instances.
        case text(() -> KvText)

        case verbatim(String)


        // MARK: : ExpressibleByStringLiteral

        @usableFromInline
        init(stringLiteral value: StringLiteralType) {
            self = .verbatim(value)
        }


        // MARK: : Equatable

        @usableFromInline
        static func ==(lhs: Content, rhs: Content) -> Bool {
            switch lhs {
            case .joined(let lhs):
                guard case .joined(let rhs) = rhs, lhs() == rhs() else { return false }
            case .localizable(let resource):
                guard case .localizable(resource) = rhs else { return false }
            case .text(let lhs):
                guard case .text(let rhs) = rhs, lhs() == rhs() else { return false }
            case .verbatim(let string):
                guard case .verbatim(string) = rhs else { return false }
            }
            return true
        }


        // MARK: Operations

        @usableFromInline
        var isEmpty: Bool {
            switch self {
            case .joined(let block):
                let (lhs, rhs) = block()
                return lhs.isEmpty && rhs.isEmpty
            case .localizable(_):
                return false    // The resolved string is unknown at the moment so `false` is returned.
            case .text(let block):
                return block().isEmpty
            case .verbatim(let string):
                return string.isEmpty
            }
        }


        // MARK: Operators

        @usableFromInline
        static func +(lhs: Content, rhs: Content) -> Content {
            guard !rhs.isEmpty else { return lhs }
            guard !lhs.isEmpty else { return rhs }


            /// - Returns: A content string when *text* is a string with no attributes.
            func PlainString(_ text: Text) -> String? {
                guard text.attributes.isEmpty,
                      case .verbatim(let string) = text.content
                else { return nil }

                return string
            }


            switch (lhs, rhs) {
            case (.verbatim(let lstring), .verbatim(let rstring)):
                return .verbatim(lstring + rstring)

            case (.verbatim(let lstring), .text(let rtext)):
                guard let rstring = PlainString((consume rtext)()) else { break }
                return .verbatim(lstring + rstring)

            case (.text(let ltext), .verbatim(let rstring)):
                let ltext = (consume ltext)()
                guard let lstring = PlainString(ltext) else { break }
                return .verbatim(lstring + rstring)

            case (.text(let ltext), .text(let rtext)):
                let text = (consume ltext)() + (consume rtext)()
                return text.attributes.isEmpty ? text.content : .text({ text })

            case (.verbatim(let lstring), .joined(let block)):
                let (mtext, rtext) = (consume block)()
                guard let mstring = PlainString(mtext) else { break }
                return .joined { (KvText(content: .verbatim(lstring + mstring)), rtext) }

            case (.joined(let block), .verbatim(let rstring)):
                let (ltext, mtext) = block()
                guard let mstring = PlainString(mtext) else { break }
                return .joined { (ltext, KvText(content: .verbatim(mstring + rstring))) }

            case (.localizable, _), (_, .localizable), (.text, .joined), (.joined, .text), (.joined, .joined):
                break
            }

            return .joined { (KvText(content: lhs), KvText(content: rhs)) }
        }

    }



    // MARK: .Attributes

    @usableFromInline
    struct Attributes : Equatable {

        @usableFromInline
        static let empty: Self = .init()


        /// Attributes those are rendered as CSS styles.
        @usableFromInline
        private(set) var styles: [Style : Any] = .init()

        /// Attributes those are rendered as HTML tags.
        @usableFromInline
        private(set) var wrappers: [Wrapper : Any] = .init()


        @usableFromInline
        init() { }


        @usableFromInline
        init(transform: (inout Attributes) -> Void) {
            transform(&self)
        }


        // MARK: .Style

        /// Attributes those are rendered as CSS styles.
        @usableFromInline
        enum Style : Hashable, Comparable {
            case font
            case fontWeight
            case foregroundStyle
            case isItalic
        }


        // MARK: .Wrapper

        /// Attributes those are rendered as HTML tags.
        @usableFromInline
        enum Wrapper : Hashable, Comparable {
            case characterStyle
            case linkURL
        }


        // MARK: : Equatable

        @usableFromInline
        static func ==(lhs: Attributes, rhs: Attributes) -> Bool {
            guard lhs.styles.count == rhs.styles.count,
                  lhs.wrappers.count == rhs.wrappers.count
            else { return false }

            for (key, lhs) in lhs.styles {
                switch key {
                case .font:
                    guard cast(lhs, as: \.font) == rhs.font else { return false }
                case .fontWeight:
                    guard cast(lhs, as: \.fontWeight) == rhs.fontWeight else { return false }
                case .foregroundStyle:
                    guard cast(lhs, as: \.foregroundStyle) == rhs.foregroundStyle else { return false }
                case .isItalic:
                    guard cast(lhs, as: \.isItalic) == rhs.isItalic else { return false }
                }
            }

            for (key, lhs) in lhs.wrappers {
                switch key {
                case .characterStyle:
                    guard cast(lhs, as: \.characterStyle) == rhs.characterStyle else { return false }
                case .linkURL:
                    guard cast(lhs, as: \.linkURL) == rhs.linkURL else { return false }
                }
            }

            return true
        }


        // MARK: Subscripts

        @usableFromInline
        subscript<T>(style: Style) -> T? {
            get { styles[style].map { $0 as! T } }
            set { styles[style] = newValue }
        }


        @usableFromInline
        subscript<T>(wrapper: Wrapper) -> T? {
            get { wrappers[wrapper].map { $0 as! T } }
            set { wrappers[wrapper] = newValue }
        }


        // MARK: Properties

        @usableFromInline
        var font: KvFont?? { get { self[.font] } set { self[.font] = newValue } }

        @usableFromInline
        var fontWeight: KvFont.Weight?? { get { self[.fontWeight] } set { self[.fontWeight] = newValue } }

        @usableFromInline
        var isItalic: Bool? { get { self[.isItalic] } set { self[.isItalic] = newValue } }

        @usableFromInline
        var characterStyle: CharacterStyle? { get { self[.characterStyle] } set { self[.characterStyle] = newValue } }

        @usableFromInline
        var foregroundStyle: KvColor?? { get { self[.foregroundStyle] } set { self[.foregroundStyle] = newValue } }

        /// - Note: It's not an `URL` due to the errors with `borrowing` keyword in come cases.
        @usableFromInline
        var linkURL: URL? { get { self[.linkURL] } set { self[.linkURL] = newValue } }


        // MARK: .CharacterStyle

        @usableFromInline
        enum CharacterStyle {
            case `subscript`, superscript
        }


        // MARK: Operations

        @usableFromInline
        var isEmpty: Bool { self == .empty }


        /// This method reduces number of explicit type declarations.
        private static func cast<T>(_ value: Any, as: KeyPath<Self, T?>) -> T { value as! T }


        func htmlAttributes(in context: borrowing KvHtmlContext) -> KvHtmlKit.Attributes? {
            let htmlAttributes = KvHtmlKit.Attributes { attributes in
                styles.keys
                   .sorted()
                   .forEach { key in
                       let value = styles[key]!

                       switch key {
                       case .font:
                           attributes.append(optionalStyles: Attributes.cast(value, as: \.font)?.cssStyle(in: context))
                       case .fontWeight:
                           attributes.append(optionalStyles: Attributes.cast(value, as: \.fontWeight).map { "font-weight:\($0.cssValue)" })
                       case .foregroundStyle:
                           attributes.append(optionalStyles: (Attributes.cast(value, as: \.foregroundStyle)?.cssExpression(in: context)).map { "color:\($0)" })
                       case .isItalic:
                           attributes.append(optionalStyles: Attributes.cast(value, as: \.isItalic) == true ? "font-style:italic" : nil)
                       }
                   }
            }

            guard !htmlAttributes.isEmpty else { return nil }
            return htmlAttributes
        }


        /// - Returns: Given bytes wrapped by tags providing application of some attributes of the receiver.
        func wrapping(_ innerFragment: consuming KvHtmlRepresentation.Fragment) -> KvHtmlRepresentation.Fragment {
            var fragment = innerFragment

            wrappers.keys
                .sorted()
                .forEach { key in
                    let value = wrappers[key]!

                    switch key {
                    case .characterStyle:
                        let tag: KvHtmlKit.Tag = switch Attributes.cast(value, as: \.characterStyle) {
                        case .subscript: .sub
                        case .superscript: .sup
                        }
                        fragment = .tag(tag, innerHTML: fragment)

                    case .linkURL:
                        fragment = KvLinkKit.representation(url: Attributes.cast(value, as: \.linkURL), innerHTML: fragment)
                    }
                }

            return fragment
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
    func escapedPlainBytes(in context: borrowing KvLocalization.Context) -> String {
        switch content {
        case .joined(let block):
            let (lhs, rhs) = block()
            return "\(lhs.escapedPlainBytes(in: context))\(rhs.escapedPlainBytes(in: context))"
        case .localizable(let resource):
            return context.string(resource)
        case .text(let block):
            return block().escapedPlainBytes(in: context)
        case .verbatim(let string):
            return KvHtmlKit.Escaping.innerText(string)
        }
    }


    @usableFromInline
    consuming func withModifiedAttributes(_ block: (inout Attributes) -> Void) -> KvText {
        var copy = self
        block(&copy.attributes)
        return copy
    }



    // MARK: Modifiers

    // TODO: DOC
    @inlinable
    public consuming func font(_ font: Font?) -> KvText { withModifiedAttributes {
        $0.font = font
    } }


    // TODO: DOC
    @inlinable
    public consuming func fontWeight(_ weight: KvFont.Weight?) -> KvText { withModifiedAttributes {
        $0.fontWeight = weight
    } }


    // TODO: DOC
    @inlinable
    public consuming func foregroundStyle(_ style: KvColor?) -> KvText { withModifiedAttributes {
        $0.foregroundStyle = style
    } }


    // TODO: DOC
    @inlinable
    public consuming func italic() -> KvText { italic(true) }


    // TODO: DOC
    @inlinable
    public consuming func italic(_ isActive: Bool) -> KvText { withModifiedAttributes {
        $0.isItalic = isActive
    } }


    // TODO: DOC
    /// - Important: Consequent ``subscript`` and ``superscript`` modifiers ane nested.
    ///
    /// - SeeAlso: ``superscript``.
    @inlinable
    public var `subscript` : KvText { consuming get {
        switch attributes.characterStyle {
        case .none:
            return withModifiedAttributes { $0.characterStyle = .subscript }
        case .some:
            let text = self
            return KvText(content: .text { text },
                   attributes: .init { $0.characterStyle = .subscript })
        }
    } }


    // TODO: DOC
    /// - Important: Consequent ``subscript`` and ``superscript`` modifiers are nested.
    ///
    /// - SeeAlso: ``subscript``.
    @inlinable
    public var superscript : KvText { consuming get {
        switch attributes.characterStyle {
        case .none:
            return withModifiedAttributes { $0.characterStyle = .superscript }
        case .some:
            let text = self
            return KvText(content: .text { text },
                   attributes: .init { $0.characterStyle = .superscript })
        }
    } }


    // TODO: DOC
    /// Consider ``KvLink`` view then link is entire text or arbitrary view.
    @inlinable
    public consuming func link(_ url: URL) -> KvText { withModifiedAttributes {
        $0.linkURL = url
    } }



    // MARK: Operators

    @inlinable
    public static func +(lhs: consuming KvText, rhs: consuming KvText) -> KvText {
        let lhs = lhs, rhs = rhs

        guard !rhs.isEmpty else { return lhs }
        guard !lhs.isEmpty else { return rhs }

        // When both attributes are empty or equal.
        guard (lhs.attributes.isEmpty && rhs.attributes.isEmpty)
                || lhs.attributes == rhs.attributes
        else { return KvText(content: .joined { (lhs, rhs) }) }

        return .init(content: lhs.content + rhs.content, attributes: lhs.attributes)
    }


    @inlinable
    public static func +=(lhs: inout KvText, rhs: consuming KvText) { lhs = lhs + rhs }

}



// MARK: : KvView

extension KvText : KvView { public var body: KvNeverView { Body() } }



// MARK: : KvHtmlRenderable

extension KvText : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        context.representation(htmlAttributes: attributes.htmlAttributes(in: context.html)) { context, htmlAttributes in

            func ContentFragment(_ content: Content) -> KvHtmlRepresentation.Fragment {
                let innerText: String

                switch content {
                case .joined(let block):
                    return InnerHTML(block())
                case .localizable(let resource):
                    innerText = context.html.localizationContext.string(resource)
                case .text(let block):
                    return InnerHTML(block())
                case .verbatim(let string):
                    innerText = string
                }

                return .init(KvHtmlKit.Escaping.innerText(innerText))
            }


            func InnerHTML(_ text: KvText) -> KvHtmlRepresentation.Fragment {
                var fragment = ContentFragment(text.content)
                let attributes = text.attributes

                if !attributes.isEmpty {
                    fragment = .tag(.span,
                                    attributes: attributes.htmlAttributes(in: context.html) ?? .empty,
                                    innerHTML: attributes.wrapping(fragment))
                }

                return fragment
            }


            func InnerHTML(_ texts: (KvText, KvText)) -> KvHtmlRepresentation.Fragment {
                .init(InnerHTML(texts.0), InnerHTML(texts.1))
            }


            let innerFragment = ContentFragment(content)
            let textStyle = context.environmentNode?.values.font?.textStyle ?? attributes.font??.textStyle

            return .tag(
                Self.tag(for: textStyle),
                attributes: htmlAttributes ?? .empty,
                innerHTML: attributes.wrapping(innerFragment)
            )
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

    /// A space character. Is a shorthand for `Text(verbatim: " ")`.
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