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
//  KvText_Markdown.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 17.02.2024.
//

import Foundation

import Markdown



// MARK: Markdown

public typealias Md = KvText.Md


extension KvText {

    /// Initializes an instance from a localizable [Markdown](https://www.markdownguide.org) source.
    ///
    /// See ``Md`` for details and examples.
    ///
    /// A localizable *markdown* argument doesn't have to contain a valid *Markdown* source,
    /// but all the localizations have to be valid *Markdown* sources.
    @inlinable
    public init(_ markdown: Md, tableName: String? = nil, bundle: Bundle? = nil, comment: StaticString? = nil) {
        self.init(content: .string(.localizable(.init(key: markdown.rawValue, table: tableName, bundle: bundle)),
                                   transform: .markdown))
    }


    /// Initializes an instance from a non-localizable [Markdown](https://www.markdownguide.org) source.
    ///
    /// See ``Md`` for details and examples.
    @inlinable
    public init(verbatim markdown: Md) {
        self.init(content: .string(.verbatim(markdown.rawValue), transform: .markdown))
    }



    // MARK: .Md

    // - NOTE: It's not called `Markdown` to prevent collisions with the Markdown module.
    /// A lightweight container indicating that a string contains a [Markdown](https://www.markdownguide.org) source.
    ///
    /// - Note: Support of *Markdown* syntax is limited.
    ///
    /// ``Md`` is designated to reduce boilerplate code when a text contains reach formatting.
    /// For example, two expressions below produce the same result:
    /// ```swift
    /// Text("A *i* **b** [c](https://c.com)" as Md)
    ///
    /// Text("A ")
    /// + Text("i").italic()
    /// + .space + Text("b").fontWeight(.semibold)
    /// + .space + Text("c").link(URL(string: "https://c.com")!)
    /// ```
    ///
    /// ``Md`` supports special HTML characters and explicit *Unicode* codes:
    /// ```swift
    /// // Equal to Text("€€€")
    /// Text("&#8364;&#x20AC;&euro;" as Md)
    /// ```
    ///
    /// Also ``Md`` is useful for localized text when formatting depends on locale.
    public struct Md : ExpressibleByStringLiteral, ExpressibleByStringInterpolation {

        public let rawValue: String



        @inlinable
        public init(_ string: String) { self.rawValue = string }



        // MARK: : ExpressibleByStringLiteral

        @inlinable
        public init(stringLiteral value: StringLiteralType) {
            self.init(value)
        }



        // MARK: Operations

        /// - Returns: Representation of the receiver as a ``KvText`` instance.
        func text() -> Text {
            let document = Document(parsing: rawValue)
            var accumulator = TextAccumulator()

            accumulator.visit(document)

            return accumulator.finalize() ?? .empty
        }



        // MARK: .TextAccumulator

        private struct TextAccumulator : MarkupWalker {

            private var accumulator: Accumulator = .init()


            // MARK: .Accumulator

            /// Holds last element of stack of accumulation contexts. For example, contexts are used to process superscripts and subscripts via HTML tags.
            private class Accumulator {

                let parent: Accumulator?

                let attribute: Attribute?

                var text: KvText? {
                    switch attribute {
                    case .subscript:
                        _text?.subscript
                    case .superscript:
                        _text?.superscript
                    case .none:
                        _text
                    }
                }


                init() {
                    self.parent = nil
                    self.attribute = nil
                }


                private init(parent: consuming Accumulator, attribute: Attribute?) {
                    self.parent = parent
                    self.attribute = attribute
                }


                private var _text: KvText?


                // MARK: .Attribute

                enum Attribute {
                    case `subscript`
                    case superscript
                }


                // MARK: Operations

                consuming func descendant(attribute: Attribute? = nil) -> Accumulator {
                    .init(parent: self, attribute: attribute)
                }


                func append(_ text: KvText) {
                    _text = _text != nil ? (_text! + text) : text
                }

            }


            // MARK: Operations

            consuming func finalize() -> KvText? {
                while accumulator.parent != nil {
                    popAttribute()
                }
                assert(accumulator.parent == nil)

                return accumulator.text
            }

            
            // MARK: : MarkupWalker

            mutating func defaultVisit(_ markup: Markup) {
                switch markup.isEmpty {
                case false:
                    processChildren(of: markup)

                case true:
                    guard let plainText = (markup as? PlainTextConvertibleMarkup)?.plainText else { return }

                    accumulator.append(KvText(verbatim: plainText))
                }
            }


            mutating func visitEmphasis(_ emphasis: Emphasis) {
                pushAttribute()
                processChildren(of: emphasis)
                popAttribute {
                    $0.italic()
                }
            }


            mutating func visitLink(_ link: Markdown.Link) {
                let destination = link.destination
                let url = destination.flatMap(URL.init(string:))

                switch link.isAutolink {
                case false:
                    pushAttribute()
                    processChildren(of: link)
                    popAttribute {
                        switch url {
                        case .some(let url):
                            $0.link(url)
                        case .none:
                            $0
                        }
                    }

                case true:
                    guard let url else { return }

                    accumulator.append(KvText(verbatim: destination!).link(url))
                }
            }


            mutating func visitStrong(_ strong: Strong) {
                pushAttribute()
                processChildren(of: strong)
                popAttribute {
                    $0.fontWeight(.semibold)
                }
            }


            mutating func visitInlineHTML(_ html: InlineHTML) {
                let tag = html.rawHTML

                switch tag {
                case "</sub>":
                    assert(accumulator.attribute == .subscript)
                    popAttribute()
                case "</sup>":
                    assert(accumulator.attribute == .superscript)
                    popAttribute()
                case "<sub>":
                    pushAttribute(.subscript)
                case "<sup>":
                    pushAttribute(.superscript)
                default:
                    accumulator.append(KvText(verbatim: tag))
                }
            }


            mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> () {
                var sourceCode = codeBlock.code

                // Trimming redundant trailing "\n".
                if sourceCode.hasSuffix("\n") {
                    sourceCode.removeLast()
                }

                insertSourceCode(sourceCode)
            }


            mutating func visitInlineCode(_ inlineCode: InlineCode) {
                insertSourceCode(inlineCode.code)
            }


            // MARK: Auxiliaries

            private mutating func pushAttribute(_ attribute: Accumulator.Attribute? = nil) {
                accumulator = accumulator.descendant(attribute: attribute)
            }


            /// - Parameter transform: A block to called for text produced in the popped context.
            private mutating func popAttribute(transform: (consuming KvText) -> KvText = { $0 }) {
                guard let parent = accumulator.parent
                else { return assertionFailure("Attempt to pop root accumulator") }

                let text = accumulator.text

                accumulator = parent

                guard let text else { return }

                accumulator.append(transform(text))
            }


            private mutating func processChildren(of markup: Markup) {
                var iterator = markup.children.makeIterator()

                do {
                    guard let first = iterator.next() else { return }

                    self.visit(first)
                }

                while let next = iterator.next() {
                    if next is BlockMarkup {
                        accumulator.append(.newLine)
                    }

                    self.visit(next)
                }
            }


            private mutating func insertSourceCode(_ sourceCode: String) {
                accumulator.append(KvText(verbatim: sourceCode).font(.system(.body, design: .monospaced)))
            }

        }

    }

}
