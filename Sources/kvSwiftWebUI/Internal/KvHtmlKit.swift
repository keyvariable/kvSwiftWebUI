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
//  KvHtmlKit.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 07.11.2023.
//

import Foundation

import kvHttpKit



struct KvHtmlKit { private init() { } }



// MARK: .Escaping

extension KvHtmlKit {

    struct Escaping {

        private init() { }



        // MARK: Operations

        /// - Returns: Escaped string to be used as inner content of an HTML tag.
        static func innerText(_ string: String) -> String {
            IteratorSequence(InnerTextIterator(string)).joined()
        }


        /// - Returns: A valid prefix of given *string* to be used as name of an HTML tag attribute. If entire *string* is valid then it is returned.
        static func attributeName(_ string: String) -> Substring {
            string.prefix { c in
                switch c {
                case "\u{00}", "\u{01}", "\u{02}", "\u{03}", "\u{04}", "\u{05}", "\u{06}", "\u{07}", "\u{08}", "\u{09}", "\u{0A}", "\u{0B}", "\u{0C}", "\u{0D}", "\u{0E}", "\u{0F}",
                    "\u{10}", "\u{11}", "\u{12}", "\u{13}", "\u{14}", "\u{15}", "\u{16}", "\u{17}", "\u{18}", "\u{19}", "\u{1A}", "\u{1B}", "\u{1C}", "\u{1D}", "\u{1E}", "\u{1F}",
                    " ", "\\", "/", ">", "\"", "'", "=": false
                default: true
                }
            }
        }


        /// - Returns: Escaped string to be used as value of an HTML tag attribute.
        static func attributeValue(_ string: String) -> String {
            IteratorSequence(AttributeValueIterator(string)).joined()
        }



        // MARK: .InnerTextIterator

        // TODO: Unit-test.
        /// Transforms UTF-8 bytes: replaces some characters with HTML equivalents, removes special characters.
        struct InnerTextIterator : IteratorProtocol {

            init(_ string: String) {
                self.substring = Substring(string)
            }


            private var substring: Substring

            private var state: State = .normal


            // MARK: .State

            private enum State {
                case normal
                case replacement(Element)
                case end
            }


            // MARK: : IteratorProtocol

            mutating func next() -> Substring? {
                while true {
                    switch state {
                    case .normal:
                        var nextState: State?

                        let stopIndex = substring.firstIndex { c in
                            switch c {
                            case "\n":
                                nextState = .replacement("<br>")
                            case "\"":
                                nextState = .replacement("&quot;")
                            case "&":
                                nextState = .replacement("&amp;")
                            case "'":
                                nextState = .replacement("&apos;")
                            case "<":
                                nextState = .replacement("&lt;")
                            case ">":
                                nextState = .replacement("&gt;")
                            default:
                                // Unexpected control characters are removed.
                                guard c.asciiValue.map({ $0 < 0x20 }) == true else { return false }
                                nextState = nil
                            }
                            return true
                        }

                        guard let stopIndex else {
                            state = .end
                            guard !substring.isEmpty else { return nil }
                            return substring
                        }

                        defer {
                            state = nextState ?? .normal

                            // Step over normal characters and a replaced character.
                            substring = substring[substring.index(after: stopIndex)...]
                        }

                        if stopIndex != substring.startIndex {
                            return substring[..<stopIndex]
                        }

                        // Assuming state is .replacement at this point and it will be handled in next iteration.

                    case .replacement(let replacement):
                        state = .normal
                        return replacement

                    case .end:
                        return nil
                    }
                }
            }

        }



        // MARK: .AttributeValueIterator

        // TODO: Unit-test.
        /// Escapes unescaped double quotes and filters unexpected control characters.
        struct AttributeValueIterator : IteratorProtocol {

            /// - Parameter state: State is external to handle sequences those are split between byte regions. Initialy it must be `.normal`.
            init(_ string: String) {
                self.substring = Substring(string)
            }


            private var substring: Substring

            private var state: State = .normal


            // MARK: .State

            private enum State {
                case normal
                case replacement(Element)
                case end
            }


            // MARK: : IteratorProtocol

            mutating func next() -> Substring? {
                while true {
                    switch state {
                    case .normal:
                        var nextState: State?
                        /// Numer of characters to remove up to `endIndex`.
                        var endInset: Int = 0
                        /// It's used in the cycle below to handle escaped characters.
                        var backslashFlag = false

                        let stopIndex = substring.firstIndex { c in
                            switch backslashFlag {
                            case false:
                                switch c {
                                case "\t", "\n":
                                    return false
                                case "\"":
                                    nextState = .replacement("\\\"")
                                case "\\":
                                    backslashFlag = true
                                    return false
                                default:
                                    // Unexpected control characters are removed.
                                    guard c.asciiValue.map({ $0 < 0x20 }) == true else { return false }
                                    nextState = nil
                                }

                            case true:
                                backslashFlag = false
                                // Removing backslash and a control character.
                                guard c.asciiValue.map({ $0 < 0x20 }) == true else { return false }
                                (nextState, endInset) = (nil, 1)
                            }
                            return true
                        }

                        guard let stopIndex else {
                            state = .end
                            guard !substring.isEmpty else { return nil }
                            return !backslashFlag ? substring : substring.dropLast()
                        }

                        defer {
                            state = nextState ?? .normal

                            // Step over normal characters and a replaced character.
                            substring = substring[substring.index(after: stopIndex)...]
                        }

                        let endIndex = endInset <= 0 ? stopIndex : substring.index(stopIndex, offsetBy: -endInset)

                        if endIndex != substring.startIndex {
                            return substring[..<endIndex]
                        }

                        // Assuming state is .replacement at this point and it will be handled in next iteration.

                    case .replacement(let replacement):
                        state = .normal
                        return replacement

                    case .end:
                        return nil
                    }
                }
            }

        }

    }

}



// MARK: .Tag

extension KvHtmlKit {

    enum Tag : Hashable {

        case a
        case body
        case br
        case div
        case h1, h2, h3, h4, h5, h6
        case img
        case link
        case meta
        case p
        case pre
        case span
        case style
        case sub
        case sup
        case title

        case raw(_ name: String, _ properties: Properties)


        // MARK: .Properties

        struct Properties : OptionSet, Hashable {

            static let requiresEndingTag = Self(rawValue: 1 << 0)


            let rawValue: UInt

        }


        // MARK: Operations

        var name: String {
            switch self {
            case .a: "a"
            case .body: "body"
            case .br: "br"
            case .div: "div"
            case .h1: "h1"
            case .h2: "h2"
            case .h3: "h3"
            case .h4: "h4"
            case .h5: "h5"
            case .h6: "h6"
            case .img: "img"
            case .link: "link"
            case .meta: "meta"
            case .p: "p"
            case .pre: "pre"
            case .span: "span"
            case .style: "style"
            case .sub: "sub"
            case .sup: "sup"
            case .title: "title"

            case .raw(let name, _): name
            }
        }

        var properties: Properties {
            switch self {
            case .a, .body, .div, .h1, .h2, .h3, .h4, .h5, .h6, .p, .pre, .span, .style, .sub, .sup, .title: .requiresEndingTag
            case .br, .img, .link, .meta: [ ]
            case .raw(_, let properties): properties
            }
        }


        /// - Important: The result can contain trailing slash.
        ///
        /// - SeeAlso: ``closing()``.
        func opening<Attributes>(css: CssAttributes? = nil, attributes: Attributes, hasContent: Bool) -> String
        where Attributes : Sequence, Attributes.Element == Attribute
        {
            // TODO: Review performance and memory consumption.
            let attributes: String = [
                attributes.lazy.map({ $0.html }).joined(separator: " "),
                css?.classAttribute?.html,
                css?.styleAttribute?.html,
            ]
                .compactMap { $0 }
                .joined(separator: " ")

            let name = name
            var openingTag = name
            if !attributes.isEmpty {
                openingTag += " \(attributes)"
            }

            return hasContent || properties.contains(.requiresEndingTag) ? "<\(openingTag)>" : "<\(openingTag)/>"
        }


        /// - Important: The result can contain trailing slash.
        ///
        /// - SeeAlso: ``closing()``.
        func opening(css: CssAttributes? = nil, attributes: Attribute?..., hasContent: Bool) -> String {
            opening(css: css, attributes: attributes.lazy.compactMap { $0 }, hasContent: hasContent)
        }


        func closing(hasContent: Bool) -> String? {
            hasContent || properties.contains(.requiresEndingTag) ? "</\(name)>" : nil
        }


        func html<Attributes>(css: CssAttributes? = nil, attributes: Attributes, innerHTML: String? = nil) -> String
        where Attributes : Sequence, Attributes.Element == Attribute
        {
            let hasContent = innerHTML != nil
            let opening = self.opening(css: css, attributes: attributes, hasContent: hasContent)

            return switch closing(hasContent: hasContent) {
            case .some(let closing):
                "\(opening)\(innerHTML!)\(closing)"
            case .none:
                opening
            }
        }


        func html(css: CssAttributes? = nil, attributes: Attribute?..., innerHTML: String? = nil) -> String {
            html(css: css, attributes: attributes.lazy.compactMap { $0 }, innerHTML: innerHTML)
        }

    }

}



// MARK: .Attribute

extension KvHtmlKit {

    /// - Note: Attributes are equal when their HTML names are equal.
    enum Attribute : Hashable {

        case `class`(AnySequence<String>)
        case content(String)
        case href(String)
        case linkRel(String)
        case media(String)
        case name(String)
        case src(String)
        case style(String)
        case type(KvHttpContentType)

        case raw(name: String, value: String?)


        // MARK: Fabrics

        static func `class`(_ values: String...) -> Self { .class(AnySequence(values)) }


        static func href(_ uri: String, relativeTo basePath: KvUrlPath?) -> Self {
            .href(Attribute.uri(uri, relativeTo: basePath))
        }

        static func href(_ url: URL) -> Self {
            .href(url.absoluteString)
        }


        static func media(colorScheme: String) -> Self { .media("(prefers-color-scheme:\(colorScheme))") }


        static func raw(_ name: String, _ value: String?) -> Self { .raw(name: name, value: value) }


        static func src(_ uri: String, relativeTo basePath: KvUrlPath?) -> Self {
            .src(Attribute.uri(uri, relativeTo: basePath))
        }


        // MARK: : Equatable

        static func ==(lhs: Self, rhs: Self) -> Bool { lhs.htmlName == rhs.htmlName }


        // MARK: : Hashable

        func hash(into hasher: inout Hasher) {
            htmlName.hash(into: &hasher)
        }


        // MARK: HTML

        var html: String {
            let value: String? = switch self {
            case .class(let names):
                names.joined(separator: " ")
            case .content(let value), .href(let value), .linkRel(let value), .media(let value), .name(let value), .src(let value), .style(let value):
                value
            case .raw(_, let value):
                value
            case .type(let contentType):
                contentType.value
            }

            return switch value {
            case .some(let valueBytes):
                "\(htmlName)=\"\(KvHtmlKit.Escaping.attributeValue(valueBytes))\""
            case .none:
                htmlName
            }
        }


        var htmlName: String {
            switch self {
            case .class(_): "class"
            case .content(_): "content"
            case .href(_): "href"
            case .linkRel(_): "rel"
            case .media(_): "media"
            case .name(_): "name"
            case .raw(let name, _): String(KvHtmlKit.Escaping.attributeName(name))
            case .src(_): "src"
            case .style(_): "style"
            case .type(_): "type"
            }
        }


        // MARK: Auxiliaries

        private static func uri(_ path: String, relativeTo basePath: KvUrlPath?) -> String {
            let path = switch path.first {
            case .none:
                ""
            case "/":
                path
            default:
                "/\(path)"
            }

            return "\(basePath?.isEmpty != false ? "" : "/\(basePath!.joined)")\(path)"
        }

    }

}



// MARK: .CssAttributes

extension KvHtmlKit {

    /// Values of attributes related to CSS.
    struct CssAttributes {

        private(set) var classes: Set<String>
        private(set) var styles: [String]?


        init(classes: Set<String> = [ ], styles: [String]? = nil) {
            self.classes = classes
            self.styles = styles
        }


        init(classes: Set<String> = [ ], style: String) {
            self.init(classes: classes, styles: [ style ])
        }


        init(classes: Set<String>, style: String?) {
            self.init(classes: classes, styles: style.map { [ $0 ] })
        }


        init(classes: String?..., style: String? = nil) {
            self.init(classes: .init(classes.lazy.compactMap { $0 }), style: style)
        }


        init(classes: String?..., styles: String?...) { self.init(
            classes: .init(classes.lazy.compactMap { $0 }),
            styles: styles.lazy.compactMap({ $0 })
        ) }


        // MARK: Fabrics

        static func union(_ lhs: Self?, _ rhs: Self?) -> Self? {
            rhs.map { union(lhs, $0) } ?? lhs
        }


        static func union(_ lhs: Self?, _ rhs: Self) -> Self {
            guard var result = lhs else { return rhs }
            result.formUnion(rhs)
            return result
        }


        // MARK: Operations

        var isEmpty: Bool { classes.isEmpty && styles?.isEmpty != false }


        var classAttribute: Attribute? {
            !classes.isEmpty ? .class(.init(classes.sorted())) : nil
        }

        var styleAttribute: Attribute? {
            guard let style = styles?.joined(separator: ";"),
                  !style.isEmpty
            else { return nil }

            return .style(style)
        }


        mutating func insert(classes: String...) {
            self.classes.formUnion(classes)
        }


        mutating func formUnion(_ rhs: Self) {
            classes.formUnion(rhs.classes)

            styles = switch (styles, rhs.styles) {
            case (.none, .none):
                nil
            case (.some(let lhs), .some(let rhs)):
                lhs + rhs
            case (.some(let style), .none), (.none, .some(let style)):
                style
            }
        }


        mutating func append(style: String) {
            styles?.append(style) ?? (styles = [ style ])
        }


        mutating func append(style: String?) {
            guard let style else { return }
            append(style: style)
        }


        mutating func append<S>(styles: S) where S : Sequence, S.Element == String {
            self.styles?.append(contentsOf: styles) ?? (self.styles = Array(styles))
        }


        mutating func append(styles: String?...) { append(styles: styles.lazy.compactMap { $0 }) }

    }

}
