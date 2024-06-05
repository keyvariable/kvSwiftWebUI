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
//  KvOrderedSet.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 05.06.2024.
//


/// A trivial implementation of an ordered set.
struct KvOrderedSet<Element> where Element : Hashable {

    /// Initializes an empty instance.
    init() { }


    /// Initializes instance from given sequnece ignoring duplicates.
    init<S>(_ elements: S) where S : Sequence, S.Element == Element {
        elements.forEach { self.insert($0) }
    }



    private var elements: [Element] = .init()
    
    private var set: Set<Element> = .init()



    // MARK: Operations

    var isEmpty: Bool { elements.isEmpty }

    var count: Int { elements.count }


    /// Inserts given element if it hasn't been inserted yet.
    ///
    /// - Returns: A boolean value indicating wheter *element* has been actually inserted.
    @discardableResult
    @usableFromInline
    mutating func insert(_ element: Element) -> Bool {
        guard set.insert(element).inserted else { return false }

        elements.append(element)

        return true
    }


    func union(_ rhs: borrowing KvOrderedSet) -> KvOrderedSet {
        var copy = self
        rhs.forEach { copy.insert($0) }
        return copy
    }


    mutating func formUnion<S>(_ rhs: S)
    where S : Sequence, S.Element == Element
    {
        rhs.forEach {
            self.insert($0)
        }
    }

}



// MARK: : ExpressibleByArrayLiteral

extension KvOrderedSet : ExpressibleByArrayLiteral {

    @usableFromInline
    init(arrayLiteral elements: Element...) {
        self.init(elements)
    }

}



// MARK: : Sequence

extension KvOrderedSet : Sequence {

    @usableFromInline
    typealias Element = Element


    @usableFromInline
    func makeIterator() -> Array<Element>.Iterator {
        elements.makeIterator()
    }

}



// MARK: : Equatable

extension KvOrderedSet : Equatable {

    @usableFromInline
    static func ==(lhs: KvOrderedSet, rhs: KvOrderedSet) -> Bool {
        lhs.elements == rhs.elements
    }

}



// MARK: : Hashable

extension KvOrderedSet : Hashable {

    @usableFromInline
    func hash(into hasher: inout Hasher) {
        elements.hash(into: &hasher)
    }

}



// MARK: Auxiliaries

extension KvOrderedSet {

    static func union(_ lhs: KvOrderedSet?, _ rhs: KvOrderedSet?) -> KvOrderedSet? {
        guard let lhs else { return rhs }
        guard let rhs else { return lhs }
        return lhs.union(rhs)
    }


    static func union(_ lhs: KvOrderedSet?, _ rhs: KvOrderedSet) -> KvOrderedSet {
        lhs?.union(rhs) ?? rhs
    }

}
