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
// TODO: Review and optimize automatic Markdown detection and KvText substitution in localized string interpolations.
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


    @usableFromInline
    init(content: Content.StringContent, transform: Content.Transform? = nil, attributes: Attributes = .empty) {
        self.init(content: Content.string(content, transform: transform), attributes: attributes)
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
    @_disfavoredOverload
    @inlinable
    public init<S>(_ content: S) where S : StringProtocol {
        self.init(verbatim: String(content))
    }


    // TODO: DOC
    /// Initializes an instance with a localized string key.
    /// 
    /// ## String Interpolations
    ///
    /// ``KvLocalizedStringKey`` supports initialization from string interpolation literals.
    /// For example:
    /// ```swift
    /// // Localization key: "Visit %@".
    /// Text("Visit \(url)")
    /// ```
    ///
    /// See ``KvLocalizedStringKey`` for details and examples.
    ///
    /// ## Markdown
    ///
    /// This method provides limited support of [Markdown](https://www.markdownguide.org ).
    /// If the localized value doesn't contain supported *Markdown* expressions then the value is used as is.
    ///
    /// Some expressions (e.g. HTML special characters) are ignored by default.
    /// Use ``KvText/md(_:tableName:bundle:comment:)`` fabric to force *Markdown* processing.
    ///
    /// For example, two expressions below produce the same result:
    /// ```swift
    /// Text("A *i* **b** [c](https://c.com)")
    ///
    /// Text("A")
    /// + .space + Text("i").italic()
    /// + .space + Text("b").fontWeight(.semibold)
    /// + .space + Text("c").link(URL(string: "https://c.com")!)
    /// ```
    @inlinable
    public init(_ key: KvLocalizedStringKey, tableName: String? = nil, bundle: Bundle? = nil, comment: StaticString? = nil) {
        self.init(content: .string(.localizable(.init(key: key, table: tableName, bundle: bundle)), transform: .auto))
    }


    /// Replaces `"%n$@"` specifiers with `KvText` instances from *attributes*
    init(format: String, arguments: [KvLocalizedStringKey.StringInterpolation.Argument], attributes: Attributes = .empty) {
        var rest = Substring(format)

        self.init()

        while let match = rest.firstMatch(of: #/%(?<index>\d+)\$T/#) {
            defer { rest = rest[match.range.upperBound...] }

            if match.range.lowerBound != rest.startIndex {
                self += KvText(rest[..<match.range.lowerBound])
            }

            let text = Int(match.output.index).flatMap { index -> KvText? in
                // As stated in printf standard, explicit indices start from 1.
                switch arguments[index - 1] {
                case .cVarArg(_, format: _):
                    assertionFailure("Internal inconsistency: \"%n$T\" format specifiers are allowed for KvText arguments only")
                    return nil
                case .text(let text):
                    return text
                }
            }

            self += text ?? KvText(rest[match.range])
        }

        if !rest.isEmpty {
            self += KvText(rest)
        }
    }



    // MARK: .Content

    @usableFromInline
    enum Content : Equatable, ExpressibleByStringLiteral {

        /// - Note: Block is used to reduce size of `Content` instances.
        case joined(() -> (KvText, KvText))

        case string(StringContent, transform: Transform? = nil)

        /// It can be used, when attributes of a text can't be merged with the associated child text. E.g. superscript inside subscript.
        ///
        /// - Note: Block is used to reduce size of `Content` instances.
        case text(() -> KvText)


        // MARK: .StringContent

        @usableFromInline
        enum StringContent : Equatable {

            case localizable(KvLocalization.StringResource)
            case verbatim(String)


            // MARK: Operations

            var arguments: [KvLocalizedStringKey.StringInterpolation.Argument] {
                switch self {
                case .localizable(let resource):
                    switch resource.key.value {
                    case .final(_):
                        [ ]
                    case .formatted(format: _, arguments: let arguments):
                        arguments
                    }
                case .verbatim(_):
                    [ ]
                }
            }


            /// - Returns: The content in given localization context.
            func string(in context: borrowing KvLocalization.Context, options: KvLocalization.Context.Options) -> String {
                switch self {
                case .localizable(let resource):
                    context.string(resource, options: options)
                case .verbatim(let value):
                    value
                }
            }

        }


        // MARK: .Transform

        @usableFromInline
        enum Transform : Equatable {

            case auto
            case markdown


            // MARK: Operations

            func apply(to string: String, arguments: [KvLocalizedStringKey.StringInterpolation.Argument]) -> KvText? {
                let md = Md(string)

                return switch self {
                case .auto:
                    md.text(arguments: arguments, options: .requireSupportedMarkup)
                case .markdown:
                    md.text(arguments: arguments)
                }
            }

        }


        // MARK: : ExpressibleByStringLiteral

        @usableFromInline
        init(stringLiteral value: StringLiteralType) {
            self = .string(.verbatim(value))
        }


        // MARK: : Equatable

        @usableFromInline
        static func ==(lhs: Content, rhs: Content) -> Bool {
            switch lhs {
            case .joined(let lhs):
                guard case .joined(let rhs) = rhs, lhs() == rhs() else { return false }
            case .string(let content, let transform):
                guard case .string(content, transform) = rhs else { return false }
            case .text(let lhs):
                guard case .text(let rhs) = rhs, lhs() == rhs() else { return false }
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
            case .string(let content, transform: let transform):
                switch (content, transform) {
                case (.verbatim(let string), .none):
                    return string.isEmpty
                default:
                    return false    // The localized or transformed string is unknown at the moment so `false` is returned.
                }
            case .text(let block):
                return block().isEmpty
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
                      case .string(.verbatim(let string), .none) = text.content
                else { return nil }

                return string
            }


            switch (lhs, rhs) {
            case (.string(.verbatim(let lstring), .none), .string(.verbatim(let rstring), .none)):
                return .string(.verbatim(lstring + rstring), transform: nil)

            case (.string(.verbatim(let lstring), .none), .text(let rtext)):
                guard let rstring = PlainString((consume rtext)()) else { break }
                return .string(.verbatim(lstring + rstring), transform: nil)

            case (.text(let ltext), .string(.verbatim(let rstring), .none)):
                let ltext = (consume ltext)()
                guard let lstring = PlainString(ltext) else { break }
                return .string(.verbatim(lstring + rstring), transform: nil)

            case (.text(let ltext), .text(let rtext)):
                let text = (consume ltext)() + (consume rtext)()
                return text.attributes.isEmpty ? text.content : .text({ text })

            case (.string(.verbatim(let lstring), .none), .joined(let block)):
                let (mtext, rtext) = (consume block)()
                guard let mstring = PlainString(mtext) else { break }
                return .joined { (KvText(content: .verbatim(lstring + mstring)), rtext) }

            case (.joined(let block), .string(.verbatim(let rstring), .none)):
                let (ltext, mtext) = block()
                guard let mstring = PlainString(mtext) else { break }
                return .joined { (ltext, KvText(content: .verbatim(mstring + rstring))) }

            case (.string(.localizable, _), _), (_, .string(.localizable, _)),
                (.string(.verbatim, .some), _), (_, .string(.verbatim, .some)),
                (.text, .joined), (.joined, .text), (.joined, .joined):
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


        @usableFromInline
        init() { }


        @usableFromInline
        init(transform: (inout Attributes) -> Void) {
            transform(&self)
        }


        init(from context: borrowing KvHtmlRepresentationContext) {
            self.init()

            guard let environment = context.environmentNode?.values else { return }

            if let font = environment.font {
                self.font = font
            }
            if let foregroundColor = environment.foregroundStyle?.foregroundColor() {
                self.foregroundStyle = foregroundColor
            }
        }


        private var regular: KvOrderedDictionary<RegularKey, Any> = [:]

        /// Attributes those are rendered as HTML tags.
        private var wrappers: KvOrderedDictionary<WrapperKey, Any> = [:]


        // MARK: .RegularKey

        @usableFromInline
        enum RegularKey : Hashable, Comparable {
            case font
            case fontDesign
            case fontWeight
            case foregroundStyle
            case help
            case hyphenation
            case isItalic
            case tag
        }


        // MARK: .WrapperKey

        /// Attributes those are rendered as HTML tags.
        @usableFromInline
        enum WrapperKey : Hashable, Comparable {
            case characterStyle
            case linkURL
        }


        // MARK: Fabrics

        /// - Returns: Merge result of *rhs* over *base*.
        static func merged(_ addition: borrowing Attributes, over base: Attributes) -> Attributes {
            var result = base

            // Some properties are not cascaded.
            result.tag = nil

            result.regular.merge(addition.regular, uniquingKeysWith: { lhs, rhs in rhs })
            result.wrappers.merge(addition.wrappers, uniquingKeysWith: { lhs, rhs in rhs })

            return result
        }


        // MARK: : Equatable

        @usableFromInline
        static func ==(lhs: Attributes, rhs: Attributes) -> Bool {
            guard lhs.regular.count == rhs.regular.count,
                  lhs.wrappers.count == rhs.wrappers.count
            else { return false }

            for (key, lhs) in lhs.regular {
                switch key {
                case .font:
                    guard cast(lhs, as: \.font) == rhs.font else { return false }
                case .fontDesign:
                    guard cast(lhs, as: \.fontDesign) == rhs.fontDesign else { return false }
                case .fontWeight:
                    guard cast(lhs, as: \.fontWeight) == rhs.fontWeight else { return false }
                case .foregroundStyle:
                    guard cast(lhs, as: \.foregroundStyle) == rhs.foregroundStyle else { return false }
                case .help:
                    guard cast(lhs, as: \.help) == rhs.help else { return false }
                case .hyphenation:
                    guard cast(lhs, as: \.hyphenation) == rhs.hyphenation else { return false }
                case .isItalic:
                    guard cast(lhs, as: \.isItalic) == rhs.isItalic else { return false }
                case .tag:
                    guard cast(lhs, as: \.tag) == rhs.tag else { return false }
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
        subscript<T>(style: RegularKey) -> T? {
            get { regular[style].map { $0 as! T } }
            set { regular[style] = newValue }
        }


        @usableFromInline
        subscript<T>(wrapper: WrapperKey) -> T? {
            get { wrappers[wrapper].map { $0 as! T } }
            set { wrappers[wrapper] = newValue }
        }


        // MARK: Properties

        /// .none — unset, .some(nil) — explicitly cleared.
        @usableFromInline
        var font: KvFont?? { get { self[.font] } set { self[.font] = newValue } }

        /// .none — unset, .some(nil) — explicitly cleared.
        @usableFromInline
        var fontDesign: KvFont.Design?? { get { self[.fontDesign] } set { self[.fontDesign] = newValue } }

        /// .none — unset, .some(nil) — explicitly cleared.
        @usableFromInline
        var fontWeight: KvFont.Weight?? { get { self[.fontWeight] } set { self[.fontWeight] = newValue } }

        @usableFromInline
        var help: KvText? { get { self[.help] } set { self[.help] = newValue } }

        @usableFromInline
        var hyphenation: Hyphenation? { get { self[.hyphenation] } set { self[.hyphenation] = newValue } }

        @usableFromInline
        var isItalic: Bool? { get { self[.isItalic] } set { self[.isItalic] = newValue } }

        /// .none — unset, .some(nil) — explicitly cleared.
        @usableFromInline
        var characterStyle: CharacterStyle? { get { self[.characterStyle] } set { self[.characterStyle] = newValue } }

        /// .none — unset, .some(nil) — explicitly cleared.
        @usableFromInline
        var foregroundStyle: KvColor?? { get { self[.foregroundStyle] } set { self[.foregroundStyle] = newValue } }

        /// - Note: It's not an `URL` due to the errors with `borrowing` keyword in come cases.
        @usableFromInline
        var linkURL: URL? { get { self[.linkURL] } set { self[.linkURL] = newValue } }

        @usableFromInline
        var tag: AnyHashable? { get { self[.tag] } set { self[.tag] = newValue } }


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


        /// - Parameter scope: Merged parent attributes.
        func htmlAttributes(in context: borrowing KvHtmlRepresentationContext, scope: borrowing Attributes) -> KvHtmlKit.Attributes? {
            let htmlAttributes = KvHtmlKit.Attributes { htmlAttributes in

                struct FontAccumulator {
                    var font: KvFont?
                    var design: KvFont.Design?
                    var weight: KvFont.Weight?
                }


                var fontAccumulator = FontAccumulator()

                // TODO: Use sorted dictionary or an array of keys instead of sorting
                regular.forEach { key, value in
                    switch key {
                    case .font:
                        fontAccumulator.font = Attributes.cast(value, as: \.font)

                    case .fontDesign:
                        fontAccumulator.design = Attributes.cast(value, as: \.fontDesign)

                    case .fontWeight:
                        fontAccumulator.weight = Attributes.cast(value, as: \.fontWeight)

                    case .foregroundStyle:
                        htmlAttributes.append(optionalStyles: (Attributes.cast(value, as: \.foregroundStyle)?.cssExpression(in: context.html)).map { "color:\($0)" })

                    case .help:
                        htmlAttributes[.title] = .string(Attributes.cast(value, as: \.help).plainText(in: context.localizationContext))

                    case .hyphenation:
                        htmlAttributes.insert(classes: context.html.cssHyphenationClass(for: Attributes.cast(value, as: \.hyphenation)))

                    case .isItalic:
                        htmlAttributes.append(optionalStyles: Attributes.cast(value, as: \.isItalic) == true ? "font-style:italic" : nil)

                    case .tag:
                        htmlAttributes[.id] = KvViewConfiguration.idAttributeValue(value)
                    }
                }


                func Resolve(fontDesign: KvFont.Design?, against fontFamily: KvFont.Family?) -> KvFont.Design? {
                    guard let fontDesign,
                          case .system(let currentDesign) = fontFamily,
                          fontDesign != currentDesign
                    else { return nil }

                    return fontDesign
                }


                switch fontAccumulator.font {
                case .some(var font):
                    font.family = Resolve(fontDesign: fontAccumulator.design, against: font.family)
                        .map { .system($0) }
                    ?? font.family

                    font.weight = fontAccumulator.weight ?? font.weight

                    htmlAttributes.append(optionalStyles: font.cssStyle(in: context))

                case .none:
                    let resolvedDesign = Resolve(fontDesign: fontAccumulator.design, against: scope.font??.family)
                    htmlAttributes.append(optionalStyles: (consume resolvedDesign).map { "font-family:\(KvHtmlContext.systemFontCSS(design: $0))" })

                    htmlAttributes.append(optionalStyles: fontAccumulator.weight.map { "font-weight:\($0.cssValue)" })
                }
            }

            guard !htmlAttributes.isEmpty else { return nil }
            return htmlAttributes
        }


        /// - Returns: Given bytes wrapped by tags providing application of some attributes of the receiver.
        func wrapping(_ innerFragment: consuming KvHtmlRepresentation.Fragment,
                      in context: borrowing KvHtmlRepresentationContext
        ) -> KvHtmlRepresentation.Fragment {
            var fragment = innerFragment

            wrappers.forEach { key, value in
                switch key {
                case .characterStyle:
                    let tag: KvHtmlKit.Tag = switch Attributes.cast(value, as: \.characterStyle) {
                    case .subscript: .sub
                    case .superscript: .sup
                    }
                    fragment = .tag(tag, innerHTML: fragment)

                case .linkURL:
                    fragment = KvLinkKit.representation(url: Attributes.cast(value, as: \.linkURL), innerHTML: fragment, in: context)
                }
            }

            return fragment
        }

    }



    // MARK: .Case

    // TODO: DOC
    public enum Case : Hashable, CaseIterable {

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



    // MARK: .Hyphenation

    /// This type declares available variants of hyphenation in multiline texts.
    public enum Hyphenation : Hashable, CaseIterable {
        /// Browsers will use built-in algorithms.
        case automatic
        /// Hyphens can appear only at explicitly declared positions.
        case manual
    }



    // MARK: Operations

    @inlinable
    public var isEmpty: Bool { content.isEmpty }


    /// - Returns: The receiver's content without attributes.
    ///
    /// - SeeAlso: ``escapedPlainBytes(in:)``.
    func plainText(in context: borrowing KvLocalization.Context) -> String {
        var string: String

        switch content {
        case .joined(let block):
            let (lhs, rhs) = block()
            string = "\(lhs.plainText(in: context))\(rhs.plainText(in: context))"

        case .string(let content, transform: let transform):
            string = content.string(in: context, options: [ ])

            if let text = transform?.apply(to: string, arguments: content.arguments) {
                string = text.plainText(in: context)
            }

        case .text(let block):
            string = block().plainText(in: context)
        }

        switch attributes.characterStyle {
        case .subscript:
            string = "_(\(string))"
        case .superscript:
            string = "^(\(string))"
        case .none:
            break
        }

        return string
    }


    /// - Returns: The receiver's content without attributes applying HTML escaping for the inner text.
    ///
    /// -  SeeAlso: ``plainText(in:)``.
    func escapedPlainBytes(in context: borrowing KvLocalization.Context) -> String {
        KvHtmlKit.Escaping.innerText(plainText(in: context))
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
    public consuming func fontDesign(_ design: KvFont.Design?) -> KvText { withModifiedAttributes {
        $0.fontDesign = design
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
    public consuming func help(_ text: KvText) -> KvText { withModifiedAttributes {
        // This modifier duplicates ``KvView/help(_:)`` to provide tooltips
        // when text is an argument of `KvLocalizedStringKey` string interpolation.

        $0.help = text
    } }


    /// An overload of ``help(_:)-i8et`` modifier.
    @inlinable
    public consuming func help(_ key: KvLocalizedStringKey) -> KvText { help(KvText(key)) }


    /// An overload of ``help(_:)-i8et`` modifier.
    @_disfavoredOverload
    @inlinable
    public consuming func help<S>(_ string: S) -> KvText
    where S : StringProtocol
    { help(KvText(string)) }


    /// This modifier declares hyphenation applied to multiline texts inside this view.
    @inlinable
    public consuming func hyphenation(_ hyphenation: Hyphenation) -> KvText { withModifiedAttributes {
        $0.hyphenation = hyphenation
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
    /// - Important: Consequent ``subscript`` and ``superscript`` modifiers are nested.
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


    /// An overload of ``KvView/tag(_:)`` modifier that preserves `KvText` return type.
    @inlinable
    public consuming func tag<T>(_ tag: T) -> KvText
    where T : Hashable
    {
        withModifiedAttributes { $0.tag = tag }
    }



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
        /// Avoiding redundant wrappers in some cases.
        var candidate = self

        while candidate.attributes.isEmpty {
            switch candidate.content {
            case .joined(_):
                return KvText.renderHTML(for: candidate, in: context)

            case .string(let content, transform: let transform):
                let string = content.string(in: context.localizationContext,
                                            options: .textPlaceholders)
                let arguments = content.arguments

                switch transform?.apply(to: string, arguments: arguments) {
                case .some(let text):
                    candidate = text
                case .none:
                    return KvText.renderHTML(for: KvText(format: string, arguments: arguments), in: context)
                }

            case .text(let block):
                candidate = block()
            }
        }

        return KvText.renderHTML(for: candidate, in: context)
    }


    private static func renderHTML(for text: KvText, in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        let scope = Attributes(from: context)

        return context.representation(htmlAttributes: text.attributes.htmlAttributes(in: context, scope: scope)) { context, htmlAttributes in
            let innerFragment = contentFragment(text.content, in: context, scope: .merged(text.attributes, over: scope))
            let textStyle = scope.font??.textStyle ?? text.attributes.font??.textStyle

            return .tag(
                KvText.tag(for: textStyle),
                attributes: htmlAttributes ?? .empty,
                innerHTML: text.attributes.wrapping(innerFragment, in: context)
            )
        }
    }


    private static func contentFragment(_ content: Content,
                                        in context: borrowing KvHtmlRepresentationContext,
                                        scope: borrowing Attributes
    ) -> KvHtmlRepresentation.Fragment {
        switch content {
        case .joined(let block):
            return innerHTML(block(), in: context, scope: scope)

        case .string(let content, transform: let transform):
            let string = content.string(in: context.localizationContext, options: .textPlaceholders)

            return switch transform {
            case .some(let transform):
                contentFragment(
                    .text {
                        transform.apply(to: string, arguments: content.arguments)
                        ?? KvText(format: string, arguments: content.arguments)
                    },
                    in: context,
                    scope: scope
                )
            case .none:
                .init(KvHtmlKit.Escaping.innerText(string))
            }

        case .text(let block):
            return innerHTML(block(), in: context, scope: scope)
        }
    }


    private static func innerHTML(_ text: KvText,
                                  in context: borrowing KvHtmlRepresentationContext,
                                  scope: borrowing Attributes
    ) -> KvHtmlRepresentation.Fragment {
        let attributes = text.attributes

        switch attributes.isEmpty {
        case false:
            let fragment = contentFragment(text.content, in: context, scope: .merged(attributes, over: scope))

            return .tag(.span,
                        attributes: attributes.htmlAttributes(in: context, scope: scope) ?? .empty,
                        innerHTML: attributes.wrapping(fragment, in: context))

        case true:
            return contentFragment(text.content, in: context, scope: scope)
        }
    }


    private static func innerHTML(_ texts: (KvText, KvText),
                                  in context: borrowing KvHtmlRepresentationContext,
                                  scope: borrowing Attributes
    ) -> KvHtmlRepresentation.Fragment {
        .init(innerHTML(texts.0, in: context, scope: scope),
              innerHTML(texts.1, in: context, scope: scope))
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

    /// An empty instance. It's a shorthand for `Text(verbatim: "")`.
    @inlinable
    public static var empty: Self { .init(" ") }

    /// A new line character ("\n"). It's a shorthand for `Text(verbatim: "\n")`.
    @inlinable
    public static var newLine: Self { .init("\n") }

    /// A space character. It's a shorthand for `Text(verbatim: " ")`.
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



// MARK: Legacy

extension KvText {

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    // TODO: Delete in 0.7.0
    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
    @available(*, unavailable, message: "Static localized string resources are not allowed due to localization is dymanic")
    @inlinable
    public init(_ resource: LocalizedStringResource) {
        self.init(verbatim: String(localized: resource))
    }
#endif // os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

}
