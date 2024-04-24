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
//  KvLocalizedStringKeyTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 22.02.2024.
//

import XCTest

@testable import kvSwiftWebUI



final class KvLocalizedStringKeyTests : XCTestCase {

    // MARK: - .testInitFromStringInterpolation()

    func testInitFromStringInterpolation() {

        func Assert(_ input: KvLocalizedStringKey, expectedFormat expected: String) {
            guard case .formatted(let format, _) = input.value
            else { return XCTFail("Unexpected input.value: \(input.value)") }

            XCTAssertEqual(format, expected)
        }

        let i = 1 as Int , i8 = 2 as Int8 , i16 = 3 as Int16 , i32 = 4 as Int32 , i64 = 5 as Int64
        let u = 6 as UInt, u8 = 7 as UInt8, u16 = 8 as UInt16, u32 = 9 as UInt32, u64 = 10 as UInt64
        let f = 1.23 as Float, d = 4.56 as Double
        let s = "string"
        let date = Date()
        let url = URL(string: "https://swift.org")!

        Assert("i=\(i),i8=\(i8),i16=\(i16),i32=\(i32),i64=\(i64)",
               expectedFormat: "i=\(KvLocalizedStringKey.StringInterpolation.Constants.formatInt),i8=%d,i16=%d,i32=%d,i64=%lld")
        Assert("u=\(u),u8=\(u8),u16=\(u16),u32=\(u32),u64=\(u64)",
               expectedFormat: "u=\(KvLocalizedStringKey.StringInterpolation.Constants.formatUInt),u8=%u,u16=%u,u32=%u,u64=%llu")
        Assert("f=\(f),lf=\(d)", expectedFormat: "f=%g,lf=%g")
        Assert("s=\(s)", expectedFormat: "s=%@")
        Assert("date=\(date),url=\(url)", expectedFormat: "date=%@,url=%@")
    }

}
