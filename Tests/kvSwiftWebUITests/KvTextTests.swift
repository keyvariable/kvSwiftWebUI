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

        func Assert(_ input: KvLocalizedStringKey, expected: KvText) {
            XCTAssertEqual(KvTestKit.renderHTML(for: KvText(input)), KvTestKit.renderHTML(for: expected), "input: \(input), expected: \(expected)")
        }

        // Emphasis, strong, links, normalized whitespace
        Assert("A *i* **b**\n[c](https://c.com)",
               expected: KvText("A ") + KvText("i").italic() + .space + KvText("b").fontWeight(.semibold) + .space + KvText("c").link(URL(string: "https://c.com")!))
        // Superscripts and subscripts
        Assert("v<sub>x</sub> = 3<sup>0.5</sup>",
               expected: KvText("v") + KvText("x").subscript + KvText(" = 3") + KvText("0.5").superscript)

        // String without Markdown
        Assert("A\nB\n\nC", expected: KvText(verbatim: "A\nB\n\nC"))

        // Unsupported markup
        Assert("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n", expected: KvText("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n"))

        // Aguments of `KvText` type.
        Assert("Text: \(KvText("text"))", expected: KvText("Text: text"))
        Assert("Text: *\(KvText("**b**, i"))*", expected: KvText("Text: ") + (KvText("b").fontWeight(.semibold) + KvText(", i")).italic())
    }



    // MARK: - .testPlainText()

    func testPlainText() {

        func Assert(_ input: KvText, expected: String) {
            XCTAssertEqual(input.plainText(in: .disabled), expected, "input: \(input); expected: \(expected)")
        }

        // Emphasis, strong, links
        Assert(KvText("A ") + KvText("i").italic() + .space + KvText("b").fontWeight(.semibold) + .space + KvText("c").link(URL(string: "https://c.com")!),
               expected: "A i b c")
        // Superscripts and subscripts
        Assert(KvText("v") + KvText("x").subscript + KvText(" = 3") + KvText("0.5").superscript,
               expected: "v_(x) = 3^(0.5)")
    }



    // MARK: - .testFabricMd()

    func testFabricMd() {

        func Assert(_ input: String, expected: KvText) {
            let result = KvText.md(.init(input))
            XCTAssertEqual(KvTestKit.renderHTML(for: result), KvTestKit.renderHTML(for: expected), "input: \(input), expected: \(expected)")
        }

        // Emphasis, strong, links
        Assert("A *i* **b** [c](https://c.com)",
               expected: KvText("A ") + KvText("i").italic() + .space + KvText("b").fontWeight(.semibold) + .space + KvText("c").link(URL(string: "https://c.com")!))
        // Line breaks and paragraphs
        Assert("A\nB\n\nC",
               expected: KvText("A B\nC"))
        // Superscripts and subscripts
        Assert("v<sub>x</sub> = 3<sup>0.5</sup>",
               expected: KvText("v") + KvText("x").subscript + KvText(" = 3") + KvText("0.5").superscript)
        // Headings, lists
        Assert("# H1\n\np1\n\n## H2\n\n- li1\n- li2\n",
               expected: KvText("H1\np1\nH2\nli1\nli2"))
        // Character codes
        Assert("&#8364;&#x20AC;&euro;",
               expected: KvText("€€€"))
        // Source code
        Assert("Inline `code`\n\n```swift\nlet a = \"a\"\n```",
               expected: KvText("Inline ") + KvText("code").fontDesign(.monospaced) + KvText("\n") + KvText("let a = \"a\"").fontDesign(.monospaced))
        // Nested markup
        Assert("*[Italic **bold** link](https://c.com)*",
               expected: (KvText("Italic ") + KvText("bold").fontWeight(.semibold) + KvText(" link")).link(URL(string: "https://c.com")!).italic())
    }

}
