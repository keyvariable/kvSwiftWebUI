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

            /// - Parameter state: State is external to handle sequences those are split between byte regions. Initially it must be `.normal`.
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
                        /// Number of characters to remove up to `endIndex`.
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
        case li
        case link
        case meta
        case ol
        case p
        case pre
        case script
        case span
        case style
        case sub
        case sup
        case title
        case ul

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
            case .li: "li"
            case .link: "link"
            case .meta: "meta"
            case .ol: "ol"
            case .p: "p"
            case .pre: "pre"
            case .script: "script"
            case .span: "span"
            case .style: "style"
            case .sub: "sub"
            case .sup: "sup"
            case .title: "title"
            case .ul: "ul"

            case .raw(let name, _): name
            }
        }

        var properties: Properties {
            switch self {
            case .a, .body, .div, .h1, .h2, .h3, .h4, .h5, .h6, .li, .ol, .p, .pre, .script, .span, .style, .sub, .sup, .title, .ul:
                .requiresEndingTag
            case .br, .img, .link, .meta: [ ]
            case .raw(_, let properties): properties
            }
        }


        /// - Important: The result can contain trailing slash.
        ///
        /// - SeeAlso: ``closing()``.
        func opening(attributes: borrowing Attributes = .empty, hasContent: Bool) -> String {
            let name = name
            var openingTag = name
            attributes.forEachExpression { openingTag += " \($0)" }

            return hasContent || properties.contains(.requiresEndingTag) ? "<\(openingTag)>" : "<\(openingTag)/>"
        }


        func closing(hasContent: Bool) -> String? {
            hasContent || properties.contains(.requiresEndingTag) ? "</\(name)>" : nil
        }


        func html(attributes: borrowing Attributes = .empty, innerHTML: String? = nil) -> String {
            let hasContent = innerHTML != nil
            let opening = self.opening(attributes: attributes, hasContent: hasContent)

            return switch closing(hasContent: hasContent) {
            case .some(let closing):
                "\(opening)\(innerHTML ?? "")\(closing)"
            case .none:
                opening
            }
        }

    }

}



// MARK: .Attribute

extension KvHtmlKit {

    /// - Note: Attributes are equal when their HTML names are equal.
    enum Attribute : Hashable {

        case alt
        case `class`
        case content
        case href
        case id
        case linkRel
        case media
        case name
        case src
        case style
        case target
        case title
        case type

        case raw(String)


        // MARK: HTML

        /// - Returns: Attribute expression with name, equality sign, quoted value.
        func html(value: String?) -> String {
            switch value {
            case .some(let valueBytes):
                "\(htmlName)=\"\(KvHtmlKit.Escaping.attributeValue(valueBytes))\""
            case .none:
                htmlName
            }
        }


        var htmlName: String {
            switch self {
            case .alt: "alt"
            case .class: "class"
            case .content: "content"
            case .href: "href"
            case .id: "id"
            case .linkRel: "rel"
            case .media: "media"
            case .name: "name"
            case .raw(let name): String(KvHtmlKit.Escaping.attributeName(name))
            case .src: "src"
            case .style: "style"
            case .target: "target"
            case .title: "title"
            case .type: "type"
            }
        }

    }

}



// MARK: .Attributes

extension KvHtmlKit {

    /// Accumulator of HTML attributes.
    struct Attributes {

        init() { }


        init(_ transform: (inout Attributes) -> Void) { transform(&self) }


        /// By default values are stored as `String` or `NSNull`. `NSNull` is used to store attributes having omitted value.
        /// Some attributes are stored as values of dedicated type, like class is stored as `Set` of strings.
        private var container: Container = .init()


        // MARK: Fabrics

        static let empty = Attributes()


        static func union(_ lhs: Attributes?, _ rhs: Attributes?) -> Attributes? {
            guard var result = lhs else { return rhs }
            guard let rhs else { return lhs }
            result.formUnion(rhs)
            return result
        }


        static func union(_ lhs: Attributes?, _ rhs: Attributes) -> Attributes {
            guard var result = lhs else { return rhs }
            result.formUnion(rhs)
            return result
        }


        static func union(_ lhs: Attributes, _ rhs: Attributes?) -> Attributes {
            var result = lhs
            if let rhs {
                result.formUnion(rhs)
            }
            return result
        }


        // MARK: .Container

        /// An ordered dictionary.
        private struct Container {

            typealias Key = Attribute
            typealias Value = Any


            private var keys: [Key] = .init()
            private var values: [Key : Value] = .init()


            // MARK: Operations

            var isEmpty: Bool { keys.isEmpty }


            subscript(key: Key) -> Value? {
                get { values[key] }
                set {
                    switch newValue {
                    case .some(let newValue):
                        guard values.updateValue(newValue, forKey: key) == nil
                        else { return /*Nothing to do*/ }

                        keys.append(key)

                    case .none:
                        guard values.removeValue(forKey: key) != nil
                        else { return /*Nothing to do*/ }

                        // Assuming keys are distinct.
                        guard let index = keys.firstIndex(of: key) else { return assertionFailure("Internal inconsistency: value for unknown «\(key)» has been successfully deleted") }
                        keys.remove(at: index)
                    }
                }
            }


            func forEach(_ body: ((key: Key, value: Value)) -> Void) {
                keys.forEach { key in
                    guard let value = values[key] else { return assertionFailure("Internal inconsistency: there is no value for «\(key)» key") }

                    body((key, value))
                }
            }

        }


        // MARK: Subscripts

        /// A subscript providing access and replacement of raw attribute values.
        ///
        /// - Important: `Attributes` type provides dedicated handling for some attributes.
        ///     For example, accumulating methods are provided for class and style attributes, type attribute can be initialized from value of `KvHttpContentType`.
        subscript(attribute: Attribute) -> Value? {
            get {
                switch attribute {
                case .class:
                    (classes?.joined(separator: " ")).map(Value.string(_:))
                case .style:
                    (styles?.joined(separator: ";")).map(Value.string(_:))
                default:
                    container[attribute].map(Value.init(_:))
                }
            }
            set { 
                switch attribute {
                case .class:
                    assertionFailure("Don't use subscript to set raw class value, use dedicated methods instead.")
                    classes = newValue?.asString.map { KvOrderedSet($0.split(separator: " ").lazy.map(String.init(_:))) }
                case .style:
                    assertionFailure("Don't use subscript to set raw style value, use dedicated methods instead.")
                    styles = newValue?.asString.map { [ $0 ] }
                default:
                    container[attribute] = newValue?.rawValue
                }
            }
        }


        /// Type casting subscript. It's used to minimize type casting expressions.
        private subscript<T>(casting attribute: Attribute) -> T? {
            get { container[attribute].map { $0 as! T } }
            set { container[attribute] = newValue }
        }


        // MARK: .Value

        /// This type is used to avoid double optionality of attribute values.
        /// Attribute are of `Value?` type.  Optionality indicates whether an attribute persists to an attribute set.
        /// `.void` value means that attribute has no value, e.g. *disabled* attribute in `<input id="date" type="date" disabled />`.
        enum Value : ExpressibleByStringLiteral, ExpressibleByStringInterpolation {

            case string(String)
            case void


            fileprivate init(_ value: Any) {
                switch value {
                case is NSNull:
                    self = .void
                default:
                    self = .string(value as! String)
                }
            }


            fileprivate var rawValue: Any {
                switch self {
                case .string(let value): value
                case .void: NSNull()
                }
            }


            init(stringLiteral value: StringLiteralType) { self = .string(value) }


            var asString: String? {
                switch self {
                case .string(let string): string
                case .void: nil
                }
            }

        }


        // MARK: Dedicated Properties

        private var classes: KvOrderedSet<String>? { get { self[casting: .class] } set { self[casting: .class] = newValue } }

        private var styles: [String]? { get { self[casting: .style] } set { self[casting: .style] = newValue } }


        // MARK: `class`

        mutating func insert(classes: KvOrderedSet<String>) {
            switch self.classes {
            case .some:
                self.classes!.formUnion(classes)
            case .none:
                guard !classes.isEmpty else { break }
                self.classes = classes
            }
        }


        mutating func insert(classes: String...) { insert(classes: classes) }


        mutating func insert<S>(classes: S) where S : Sequence, S.Element == String {
            switch self.classes {
            case .some:
                self.classes!.formUnion(classes)
            case .none:
                let classes = KvOrderedSet(classes)
                guard !classes.isEmpty else { break }
                self.classes = classes
            }
        }


        mutating func insert(optionalClasses: String?...) { insert(classes: optionalClasses.lazy.compactMap { $0 }) }


        // MARK: `href`

        /// Sets ``Attribute/href`` attribute from relative path and the base path.
        mutating func set(href path: String, relativeTo basePath: KvUrlPath? = nil) {
            container[.href] = Attributes.resolve(path: path, relativeTo: basePath)
        }


        mutating func set(href url: URL) { container[.href] = url.absoluteString }


        // MARK: `media`

        mutating func set(mediaColorScheme colorScheme: String) { container[.media] = "(prefers-color-scheme:\(colorScheme))" }


        // MARK: `src`

        /// Sets ``Attribute/src`` attribute from relative path and the base path.
        mutating func set(src path: String, relativeTo basePath: KvUrlPath? = nil) {
            container[.src] = Attributes.resolve(path: path, relativeTo: basePath)
        }


        mutating func set(src url: URL) { container[.src] = url.absoluteString }


        // MARK: `style`

        mutating func append(styles: [String]) {
            switch self.styles {
            case .some:
                self.styles!.append(contentsOf: styles)
            case .none:
                guard !styles.isEmpty else { break }
                self.styles = styles
            }
        }


        mutating func append<S>(styles: S) where S : Sequence, S.Element == String {
            switch self.styles {
            case .some:
                self.styles!.append(contentsOf: styles)
            case .none:
                let styles = Array(styles)
                guard !styles.isEmpty else { break }
                self.styles = styles
            }
        }


        mutating func append(styles: String...) { append(styles: styles) }


        mutating func append(optionalStyles: String?...) { append(styles: optionalStyles.lazy.compactMap { $0 }) }


        // MARK: `type`

        /// Sets value or ``Attribute/type`` attribute.
        mutating func set(type: KvHttpContentType) {
            container[.type] = type.value
        }


        // MARK: Operations

        /// - Note: For example, If some tag has empty string value, then the container is not empty.
        var isEmpty: Bool { container.isEmpty }


        mutating func formUnion(_ rhs: Attributes) {
            rhs.container.forEach { (key, value) in
                switch key {
                case .class:
                    insert(classes: Attributes.cast(value, as: \.classes))
                case .style:
                    append(styles: Attributes.cast(value, as: \.styles))
                default:
                    container[key] = value
                }
            }
        }


        // MARK: HTML

        /// Invokes *body* with HTML expressions for each attribute.
        func forEachExpression(_ body: (String) -> Void) {
            container.forEach { (key, value) in
                let value: String? = switch key {
                case .class:
                    Attributes.cast(value, as: \.classes).joined(separator: " ")
                case .style:
                    Attributes.cast(value, as: \.styles).joined(separator: ";")
                default:
                    Value(value).asString
                }

                body(key.html(value: value))
            }
        }


        // MARK: Auxiliaries

        /// This method reduces number of explicit type declarations.
        private static func cast<T>(_ value: Any, as: KeyPath<Attributes, T?>) -> T { value as! T }


        private static func resolve(path: String, relativeTo basePath: KvUrlPath?) -> String {
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
