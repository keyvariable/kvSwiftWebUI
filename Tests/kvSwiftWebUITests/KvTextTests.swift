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
//  KvTextTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 19.02.2024.
//

import XCTest

@testable import kvSwiftWebUI



final class KvTextTests : XCTestCase {

    // MARK: - .testInitByLocalized()

    func testInitByLocalized() {

        func Assert(_ input: String, expected: Text) {
            XCTAssertEqual(KvTestKit.renderHTML(for: Text(KvLocalizedStringKey(input))), KvTestKit.renderHTML(for: expected), "input: \(input), expected: \(expected)")
        }

        // Emphasis, strong, links, normalized whitespace
        Assert("A *i* **b**\n[c](https://c.com)",
               expected: Text("A ") + Text("i").italic() + .space + Text("b").fontWeight(.semibold) + .space + Text("c").link(URL(string: "https://c.com")!))
        // Superscripts and subscripts
        Assert("v<sub>x</sub> = 3<sup>0.5</sup>",
               expected: Text("v") + Text("x").subscript + Text(" = 3") + Text("0.5").superscript)

        // String without Markdown
        Assert("A\nB\n\nC", expected: Text(verbatim: "A\nB\n\nC"))

        // Unsupported markup
        Assert("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n", expected: Text("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n"))
    }



    // MARK: - .testPlainText()

    func testPlainText() {

        func Assert(_ input: Text, expected: String) {
            XCTAssertEqual(input.plainText(in: .disabled), expected, "input: \(input); expected: \(expected)")
        }

        // Emphasis, strong, links
        Assert(Text("A ") + Text("i").italic() + .space + Text("b").fontWeight(.semibold) + .space + Text("c").link(URL(string: "https://c.com")!),
               expected: "A i b c")
        // Superscripts and subscripts
        Assert(Text("v") + Text("x").subscript + Text(" = 3") + Text("0.5").superscript,
               expected: "v_(x) = 3^(0.5)")
    }



    // MARK: - .testFabricMd()

    func testFabricMd() {

        func Assert(_ input: String, expected: Text) {
            let result = Text.md(.init(input))
            XCTAssertEqual(KvTestKit.renderHTML(for: result), KvTestKit.renderHTML(for: expected), "input: \(input), expected: \(expected)")
        }

        // Emphasis, strong, links
        Assert("A *i* **b** [c](https://c.com)",
               expected: Text("A ") + Text("i").italic() + .space + Text("b").fontWeight(.semibold) + .space + Text("c").link(URL(string: "https://c.com")!))
        // Line breaks and paragraphs
        Assert("A\nB\n\nC",
               expected: Text("A B\nC"))
        // Superscripts and subscripts
        Assert("v<sub>x</sub> = 3<sup>0.5</sup>",
               expected: Text("v") + Text("x").subscript + Text(" = 3") + Text("0.5").superscript)
        // Headings, lists
        Assert("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n",
               expected: Text("H1\np1\nH2\nli1\nli2"))
        // Character codes
        Assert("&#8364;&#x20AC;&euro;",
               expected: Text("€€€"))
        // Source code
        Assert("Inline `code`\n\n```swift\nlet a = \"a\"\n```",
               expected: Text("Inline ") + Text("code").font(.system(.body, design: .monospaced)) + Text("\n") + Text("let a = \"a\"").font(.system(.body, design: .monospaced)))
        // Nested markup
        Assert("*[Italic **bold** link](https://c.com)*",
               expected: (Text("Italic ") + Text("bold").fontWeight(.semibold) + Text(" link")).link(URL(string: "https://c.com")!).italic())
    }

}
