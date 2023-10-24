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
//  KvConfiguration.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 01.11.2023.
//

protocol KvConfiguration {

    associatedtype MergeResult
    associatedtype OptionalMergeResult


    static func merged(_ addition: Self?, over base: Self?) -> OptionalMergeResult

    static func merged(_ addition: Self?, over base: Self) -> MergeResult

    static func merged(_ addition: Self, over base: Self?) -> MergeResult

    static func merged(_ addition: Self, over base: Self) -> MergeResult

}



extension KvConfiguration where MergeResult == Self, OptionalMergeResult == Self? {

    static func merged(_ addition: Self?, over base: Self?) -> OptionalMergeResult {
        guard let addition = addition else { return base }
        guard let base = base else { return addition }
        return merged(addition, over: base)
    }


    static func merged(_ addition: Self?, over base: Self) -> MergeResult {
        guard let addition = addition else { return base }
        return merged(addition, over: base)
    }


    static func merged(_ addition: Self, over base: Self?) -> MergeResult {
        guard let base = base else { return addition }
        return merged(addition, over: base)
    }

}



extension KvConfiguration where MergeResult == KvMergeResult<Self>, OptionalMergeResult == KvMergeResult<Self?> {

    static func merged(_ addition: Self?, over base: Self?) -> OptionalMergeResult {
        guard let addition = addition else { return .merged(base) }
        guard let base = base else { return .merged(addition) }
        return (merged(addition, over: base) as KvMergeResult<Self>).map { Optional($0) }
    }


    static func merged(_ addition: Self?, over base: Self) -> MergeResult {
        guard let addition = addition else { return .merged(base) }
        return merged(addition, over: base)
    }


    static func merged(_ addition: Self, over base: Self?) -> MergeResult {
        guard let base = base else { return .merged(addition) }
        return merged(addition, over: base)
    }

}
