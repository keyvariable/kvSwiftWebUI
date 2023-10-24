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
        static func innerText(_ string: String) -> KvHtmlBytes { .init { auxBuffers in
            let stringIterator = KvHtmlBytes.stringIterator(string, auxBuffers)

            return .init(stringIterator
                .lazy.flatMap { (pointer, count) in IteratorSequence(InnerTextIterator(pointer, count)) }
                .makeIterator()
            )
        } }


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
        static func attributeValue(_ bytes: KvHtmlBytes) -> KvHtmlBytes { .init { auxBuffers in
            var state: AttributeValueIterator.State = .normal()

            return .init(bytes.makeIterator(auxBuffers)
                .lazy.flatMap { element in IteratorSequence(AttributeValueIterator(element.pointer, element.count, state: &state)) }
                .makeIterator())
        } }



        // MARK: .InnerTextIterator

        // TODO: Unit-test.
        struct InnerTextIterator : IteratorProtocol {

            init(_ baseAddress: UnsafeRawPointer, _ count: Int) {
                buffer = .init(start: baseAddress, count: count)
            }


            private var buffer: UnsafeRawBufferPointer

            private var state: State = .normal


            // MARK: .State

            private enum State {
                case normal
                case replacement(Replacement.Bytes)
                case end
            }


            // MARK: : IteratorProtocol

            mutating func next() -> KvHtmlBytes.Element? {
                while true {
                    switch state {
                    case .normal:
                        guard let (count, newState) = buffer.enumerated()
                            .lazy.compactMap({ (offset, c) -> (Int, State?)? in
                                switch c {
                                case 0x0A: (offset, .replacement(Replacement.x0A))
                                case 0x22: (offset, .replacement(Replacement.x22))
                                case 0x26: (offset, .replacement(Replacement.x26))
                                case 0x27: (offset, .replacement(Replacement.x27))
                                case 0x3C: (offset, .replacement(Replacement.x3C))
                                case 0x3E: (offset, .replacement(Replacement.x3E))
                                default: c >= 0x20 ? nil : (offset, nil)
                                }
                            }).first
                        else {
                            let count = buffer.count
                            switch count > 0 {
                            case true:
                                state = .end
                                return (buffer.baseAddress!, count)

                            case false:
                                return nil
                            }
                        }

                        defer {
                            state = newState ?? .normal

                            let offset = count + 1  // Step over normal characters and replaced character.
                            buffer = .init(start: buffer.baseAddress!.advanced(by: offset), count: buffer.count - offset)
                        }

                        if count > 0 {
                            return (buffer.baseAddress!, count)
                        }

                    case .replacement(let replacementBytes):
                        state = .normal
                        return replacementBytes.withUnsafeBytes { ($0.baseAddress!, replacementBytes.count) }

                    case .end:
                        return nil
                    }
                }
            }


            // MARK: .Replacement

            private struct Replacement {

                typealias Bytes = ContiguousArray<UInt8>

                // - NOTE: Assuming Data literals are precompiled.

                static let x0A: Bytes = [ 0x3C, 0x62, 0x72, 0x20, 0x2F, 0x3E ]  // "\n": "<br />"
                static let x22: Bytes = [ 0x26, 0x71, 0x75, 0x6F, 0x74, 0x3B ]  // "\"": "&quot;"
                static let x26: Bytes = [ 0x26, 0x61, 0x6D, 0x70, 0x3B ]        // "&" : "&amp;"
                static let x27: Bytes = [ 0x26, 0x61, 0x70, 0x6F, 0x73, 0x3B ]  // "'" : "&apos;"
                static let x3C: Bytes = [ 0x26, 0x6C, 0x74, 0x3B ]              // "<" : "&lt;"
                static let x3E: Bytes = [ 0x26, 0x67, 0x74, 0x3B ]              // ">" : "&gt;"
            }

        }



        // MARK: .AttributeValueIterator

        // TODO: Unit-test.
        struct AttributeValueIterator : IteratorProtocol {

            /// - Parameter state: State is external to handle sequences those are split between byte regions. Initialy it must be `.normal`.
            init(_ baseAddress: UnsafeRawPointer, _ count: Int, state: UnsafeMutablePointer<State>) {
                self.buffer = .init(start: baseAddress, count: count)
                self.state = state
            }


            private var buffer: UnsafeRawBufferPointer

            private var state: UnsafeMutablePointer<State>


            // MARK: .State

            enum State {
                case normal(acceptedCount: Int = 0)
                case replacement(Replacement.Bytes)
                /// - Parameter backslashFlag: A boolean value indicating wheter byte region is ended with backslash.
                case end(backslashFlag: Bool)
            }


            // MARK: : IteratorProtocol

            mutating func next() -> KvHtmlBytes.Element? {
                while true {
                    switch state.pointee {
                    case .normal(acceptedCount: let acceptedCount):
                        /// It's used in the cycle below to handle escaped characters.
                        var backslashFlag = false

                        guard let (count, offset, newState) = buffer[acceptedCount...].enumerated()
                            .lazy.compactMap({ (offset, c) -> (Int, Int, State?)? in
                                switch backslashFlag {
                                case false:
                                    switch c {
                                    case 0x09, 0x0A: return nil
                                    case 0x22: return (offset, offset + 1, .replacement(Replacement.x22))
                                    case 0x5C: backslashFlag = true
                                    default: return c >= 0x20 ? nil : (offset, offset + 1, nil)
                                    }

                                case true:
                                    backslashFlag = false
                                    // Removing backslash and a control character.
                                    guard c >= 0x20 else { return (offset - 1, offset + 1, nil) }
                                }
                                return nil
                            }).first
                        else {
                            let count = { backslashFlag ? $0 - 1 : $0 }(buffer.count)
                            state.pointee = .end(backslashFlag: backslashFlag)

                            guard count > 0 else { return nil }

                            defer { buffer = .init(start: buffer.baseAddress!.advanced(by: buffer.count), count: 0) }
                            return (buffer.baseAddress!, count)
                        }

                        defer {
                            let offset = acceptedCount + offset
                            state.pointee = newState ?? .normal()

                            buffer = .init(start: buffer.baseAddress!.advanced(by: offset), count: buffer.count - offset)
                        }

                        if count > 0 {
                            return (buffer.baseAddress!, count)
                        }

                    case .replacement(let replacementBytes):
                        state.pointee = .normal()
                        return replacementBytes.withUnsafeBytes { ($0.baseAddress!, replacementBytes.count) }

                    case .end(backslashFlag: let backslashFlag):
                        guard !buffer.isEmpty else { return nil }

                        guard backslashFlag else {
                            state.pointee = .normal()
                            break
                        }

                        let c = buffer[0]
                        buffer = .init(start: buffer.baseAddress!.successor(), count: buffer.count - 1)

                        switch c >= 0x20 {
                        case true:
                            state.pointee = .normal(acceptedCount: 1)
                            let backslash = Replacement.x5C
                            return backslash.withUnsafeBytes { ($0.baseAddress!, backslash.count) }

                        case false:
                            state.pointee = .normal()
                        }
                    }
                }
            }


            // MARK: .Replacement

            struct Replacement {

                typealias Bytes = ContiguousArray<UInt8>

                // - NOTE: Assuming Data literals are precompiled.

                fileprivate static let x22: Bytes = [ 0x5C, 0x22 ]  // "\"" -> "\\\""
                fileprivate static let x5C: Bytes = [ 0x5C ]        // Pseudoreplacement is used at the junction of two segments.
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
        case sub
        case sup

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
            case .sub: "sub"
            case .sup: "sup"

            case .raw(let name, _): name
            }
        }

        var properties: Properties {
            switch self {
            case .a, .body, .div, .h1, .h2, .h3, .h4, .h5, .h6, .p, .pre, .span, .sub, .sup: .requiresEndingTag
            case .br, .img, .link, .meta: [ ]
            case .raw(_, let properties): properties
            }
        }

    }

}



// MARK: .Attribute

extension KvHtmlKit {

    /// - Note: Attributes are equal when their HTML names are equal.
    enum Attribute : Hashable {

        case `class`(AnySequence<String>)
        case content(KvHtmlBytes)
        case href(KvHtmlBytes)
        case linkRel(KvHtmlBytes)
        case media(KvHtmlBytes)
        case name(KvHtmlBytes)
        case src(KvHtmlBytes)
        case style(KvHtmlBytes)
        case type(KvHttpContentType)

        case raw(name: String, value: KvHtmlBytes?)


        // MARK: Fabrics

        static func `class`(_ values: String...) -> Self { .class(AnySequence(values)) }


        static func href(_ uri: String, relativeTo basePath: KvUrlPath?) -> Self {
            .href(KvHtmlBytes.from(Attribute.uri(uri, relativeTo: basePath)))
        }

        static func href(_ url: URL) -> Self {
            .href(KvHtmlBytes.from(url.absoluteString))
        }


        static func media(colorScheme: String) -> Self { .media("(prefers-color-scheme:\(colorScheme))") }


        static func raw(_ name: String, _ value: KvHtmlBytes?) -> Self { .raw(name: name, value: value) }


        static func src(_ uri: String, relativeTo basePath: KvUrlPath?) -> Self {
            .src(KvHtmlBytes.from(Attribute.uri(uri, relativeTo: basePath)))
        }


        // MARK: : Equatable

        static func ==(lhs: Self, rhs: Self) -> Bool { lhs.htmlName == rhs.htmlName }


        // MARK: : Hashable

        func hash(into hasher: inout Hasher) {
            htmlName.hash(into: &hasher)
        }


        // MARK: HTML

        var htmlBytes: KvHtmlBytes {
            let name = htmlName

            let value: KvHtmlBytes? = switch self {
            case .class(let names):
                .joined(names.lazy.map { .from($0) }, separator: " ")
            case .content(let value), .href(let value), .linkRel(let value), .media(let value), .name(let value), .src(let value), .style(let value):
                value
            case .raw(_, let value):
                value
            case .type(let contentType): .from(contentType.value)
            }

            let nameBytes: KvHtmlBytes = .from(KvHtmlKit.Escaping.attributeName(name))

            switch value {
            case .some(let valueBytes):
                return .joined(nameBytes, "=\"", KvHtmlKit.Escaping.attributeValue(valueBytes), "\"")
            case .none:
                return nameBytes
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
            case .raw(let name, _): name
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
        private(set) var style: KvHtmlBytes?


        init(classes: Set<String>, style: KvHtmlBytes? = nil) {
            self.classes = classes
            self.style = style
        }


        init(classes: String?..., style: KvHtmlBytes? = nil) {
            self.init(classes: .init(classes.lazy.compactMap { $0 }), style: style)
        }


        init(classes: String?..., styles: KvHtmlBytes?...) { self.init(
            classes: .init(classes.lazy.compactMap { $0 }),
            style: (styles.contains(where: { $0 != nil })
                    ? .joined(styles.lazy.compactMap { $0 }, separator: ";")
                    : nil)
        ) }


        // TODO: Single pass verification and concatenation of styles.
        init(classes: String?..., styles: String?...) { self.init(
            classes: .init(classes.lazy.compactMap { $0 }),
            style: (styles.contains(where: { $0?.isEmpty == false })
                    ? .joined(styles.lazy.compactMap { $0.map(KvHtmlBytes.from) }, separator: ";")
                    : nil)
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

        var isEmpty: Bool { classes.isEmpty && style == nil }


        var classAttribute: Attribute? {
            !classes.isEmpty ? .class(.init(classes.sorted())) : nil
        }

        var styleAttribute: Attribute? {
            style.map(Attribute.style(_:))
        }


        mutating func insert(classes: String...) {
            self.classes.formUnion(classes)
        }


        mutating func formUnion(_ rhs: Self) {
            classes.formUnion(rhs.classes)
            style = switch (style, rhs.style) {
            case (.none, .none):
                nil
            case (.some(let lhs), .some(let rhs)):
                .joined(lhs, rhs, separator: ";")
            case (.some(let style), .none), (.none, .some(let style)):
                style
            }
        }


        mutating func append(style: KvHtmlBytes) {
            switch self.style {
            case .some(let oldStyle):
                self.style = .joined(oldStyle, style, separator: ";")
            case .none:
                self.style = style
            }
        }


        mutating func append<S>(styles: S) where S : Sequence, S.Element == KvHtmlBytes {
            switch self.style {
            case .some(let oldStyle):
                self.style = .joined(oldStyle, .joined(styles, separator: ";"), separator: ";")
            case .none:
                self.style = .joined(styles, separator: ";")
            }
        }


        mutating func append(styles: KvHtmlBytes?...) { append(styles: styles.lazy.compactMap { $0 }) }


        mutating func append(styles: String?...) { append(styles: styles.lazy.compactMap { $0.map(KvHtmlBytes.from(_:)) }) }

    }

}
