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
//  KvLocalizationTests.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.02.2024.
//

import XCTest

@testable import kvSwiftWebUI



final class KvLocalizationTests : XCTestCase {

    // MARK: - .testMatchRateOfLanguageTags()

    func testMatchRateOfLanguageTags() {

        func Assert(_ lhs: String, _ rhs: String, expected: KvLocalization.MatchRate?) {
            XCTAssertEqual(KvLocalization.MatchRate.ofLanguageTags(lhs, rhs), expected, "lhs = \(lhs), rhs = \(rhs)")
            XCTAssertEqual(KvLocalization.MatchRate.ofLanguageTags(rhs, lhs), expected, "[SWAP] lhs = \(lhs), rhs = \(rhs)")
        }

        Assert("en", "en", expected: .exact)
        Assert("en", "EN", expected: .exact)
        Assert("zh-Hans-CN", "zh-Hans-CN", expected: .exact)
        Assert("zh-Hans-CN", "zh-hans-cn", expected: .exact)

        Assert("en", "zh", expected: nil)
        Assert("en", "eng", expected: nil)
        Assert("en-US", "eng", expected: nil)

        Assert("en", "en-US", expected: .partial(1))
        Assert("en-US", "en-GB", expected: .partial(1))
        Assert("zh-Hans-CN", "zh-cmn-Hans-CN", expected: .partial(1))
        Assert("zh-Hans-CN", "zh-Hant-CN", expected: .partial(1))

        Assert("zh-Hans-CN", "zh-Hans", expected: .partial(2))
        Assert("zh-Hans-CN", "zh-Hans-C", expected: .partial(2))
    }

}
