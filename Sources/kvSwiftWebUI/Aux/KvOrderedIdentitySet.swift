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
//  KvOrderedIdentitySet.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 01.02.2024.
//

/// A simple implementation of ordered set containing `Identifiable` elements.
/// Two elements are considered equal when they have the same ID.
///
/// - Note: It only accumulates elements, no removal or move operations.
@usableFromInline
struct KvOrderedIdentitySet<Element> where Element : Identifiable {

    /// Initializes an empty instance.
    @usableFromInline
    init() { }


    /// Initializes instance from given sequnece ignoring duplicates.
    init<S>(_ elements: S) where S : Sequence, S.Element == Element {
        elements.forEach { self.insert($0) }
    }



    private var elements: [Element] = .init()

    private var ids: Set<Element.ID> = .init()



    // MARK: Operations

    var isEmpty: Bool { elements.isEmpty }

    var count: Int { elements.count }


    /// Inserts given element if it hasn't been inserted yet.
    ///
    /// - Returns: A boolean value indicating wheter *element* has been actually inserted.
    @discardableResult
    @usableFromInline
    mutating func insert(_ element: Element) -> Bool {
        guard ids.insert(element.id).inserted else { return false }

        elements.append(element)

        return true
    }


    func union(_ rhs: borrowing KvOrderedIdentitySet) -> KvOrderedIdentitySet {
        var copy = self
        rhs.forEach { copy.insert($0) }
        return copy
    }

}



// MARK: : ExpressibleByArrayLiteral

extension KvOrderedIdentitySet : ExpressibleByArrayLiteral {

    @usableFromInline
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

}



// MARK: : Sequence

extension KvOrderedIdentitySet : Sequence {

    @usableFromInline
    typealias Element = Element


    @usableFromInline
    func makeIterator() -> Array<Element>.Iterator {
        elements.makeIterator()
    }

}



// MARK: : Equatable

extension KvOrderedIdentitySet : Equatable {

    @usableFromInline
    static func ==(lhs: KvOrderedIdentitySet, rhs: KvOrderedIdentitySet) -> Bool {
        lhs.ids == rhs.ids
    }

}



// MARK: : Hashable

extension KvOrderedIdentitySet : Hashable {

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        ids.hash(into: &hasher)
    }

}



// MARK: Auxiliaries

extension KvOrderedIdentitySet {

    static func union(_ lhs: KvOrderedIdentitySet?, _ rhs: KvOrderedIdentitySet?) -> KvOrderedIdentitySet? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs.union(rhs)
    }


    static func union(_ lhs: KvOrderedIdentitySet?, _ rhs: KvOrderedIdentitySet) -> KvOrderedIdentitySet {
        lhs?.union(rhs) ?? rhs
    }

}
