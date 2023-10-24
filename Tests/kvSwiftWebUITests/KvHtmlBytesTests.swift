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
//  KvHtmlBytesTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 18.11.2023.
//

import XCTest

@testable import kvSwiftWebUI



final class KvHtmlBytesTests : XCTestCase {

    // MARK: - testStringLiteral()

    func testStringLiteral() {

        func Assert(_ input: String) {
            let result = KvHtmlBytes.init(stringLiteral: input)
            XCTAssertEqual(result.accumulate().data, input.data(using: .utf8))
        }

        Assert(" />")
    }



    // MARK: - testTag()

    func testTag() {
        assertEqual(.tag(.br), "<br />")
        assertEqual(.tag(.link, attributes: .href("/main.css"), .linkRel("stylesheet")), "<link href=\"/main.css\" rel=\"stylesheet\" />")
    }



    // MARK: - Auxiliaries

    private func assertEqual(_ bytes: KvHtmlBytes, _ expected: String) {
        XCTAssertEqual(bytes.accumulate().data, expected.data(using: .utf8)!)
    }

}
