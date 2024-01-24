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
//  KvHtmlKitTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 17.11.2023.
//

import XCTest

@testable import kvSwiftWebUI

import kvCssKit



final class KvHtmlKitTests : XCTestCase {

    // MARK: - testAttributeValueEscaping()

    func testAttributeValueEscaping() {

        func Assert(_ input: String, expected: String) {
            XCTAssertEqual(KvHtmlKit.Escaping.attributeValue(input), expected, "input: «\(input)»")
        }

        Assert("width: 100%", expected: "width: 100%")
        Assert(KvCssLength.percents(50).css, expected: "50%")
        Assert("font: \"Times New Roman\"", expected: "font: \\\"Times New Roman\\\"")
        Assert("\"a=\\\"a\\\"\"", expected: "\\\"a=\\\"a\\\"\\\"")
        Assert("new line\n\ttab", expected: "new line\n\ttab")
    }

}
