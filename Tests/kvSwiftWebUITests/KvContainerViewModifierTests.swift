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
//  KvContainerViewModifierTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 23.01.2024.
//

import XCTest

@testable import kvSwiftWebUI



final class KvContainerViewModifierTests : XCTestCase {

    // MARK: - .testBackgroundAndPaddingOrder()

    func testBackgroundAndPaddingOrder() {
        XCTAssertEqual(
            KvTestKit.renderHTML(for: Text("1").padding(.em(2)).background(0xAABBCC as KvColor)),
            "<p style=\"padding:2em;background-color:#AABBCC\">1</p>"
        )

        XCTAssertEqual(
            KvTestKit.renderHTML(for: Text("1").background(0xAABBCC as KvColor).padding(.em(2))),
            "<div style=\"padding:2em\"><p style=\"background-color:#AABBCC\">1</p></div>"
        )
    }

}
