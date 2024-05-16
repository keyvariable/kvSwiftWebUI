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
//  KvOrderedDictionary.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 15.05.2024.
//

/// A simple implementation of an ordered dictionary.
struct KvOrderedDictionary<Key, Value>
where Key : Hashable
{

    /// Initializes an empty instance.
    init() { }


    init<S>(_ elements: S) where S : Sequence, S.Element == Element {
        elements.forEach {
            updateValue($0.value, forKey: $0.key)
        }
    }



    private var dictionary: [Key : Value] = [:]
    private var keys: [Key] = [ ]



    // MARK: Operations

    var isEmpty: Bool { dictionary.isEmpty }

    var count: Int { dictionary.count }


    subscript(key: Key) -> Value? {
        get { dictionary[key] }
        set {
            switch newValue {
            case .some(let newValue):
                updateValue(newValue, forKey: key)

            case .none:
                guard dictionary.removeValue(forKey: key) != nil,
                      let index = keys.firstIndex(of: key)
                else { break }

                keys.remove(at: index)
            }
        }
    }


    subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get { dictionary[key] ?? defaultValue() }
        set { updateValue(newValue, forKey: key) }
    }


    @discardableResult
    mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let oldValue = dictionary.updateValue(value, forKey: key)

        if oldValue == nil {
            keys.append(key)
        }

        return oldValue
    }


    mutating func merge(
        _ other: KvOrderedDictionary<Key, Value>,
        uniquingKeysWith combine: (Value, Value) throws -> Value
    ) rethrows {
        try dictionary.merge(other.dictionary, uniquingKeysWith: combine)

        other.keys.forEach {
            guard dictionary.index(forKey: $0) == nil else { return }
            keys.append($0)
        }
    }

}



// MARK: : Sequence

extension KvOrderedDictionary : Sequence {

    typealias Index = Int
    typealias Element = (key: Key, value: Value)


    subscript(index: Index) -> Element {
        dictionary[dictionary.index(forKey: keys[index])!]
    }


    func makeIterator() -> LazyMapSequence<[Key], Element>.Iterator {
        keys
            .lazy.map { dictionary[dictionary.index(forKey: $0)!] }
            .makeIterator()
    }


    func forEach(_ body: (Element) throws -> Void) rethrows {
        try keys.forEach {
            try body(dictionary[dictionary.index(forKey: $0)!])
        }
    }

}



// MARK: : Collection

extension KvOrderedDictionary : Collection {

    var startIndex: Index { keys.startIndex }

    var endIndex: Index { keys.endIndex }


    func index(after i: Index) -> Index { i + 1 }
}



// MARK: : ExpressibleByArrayLiteral

extension KvOrderedDictionary : ExpressibleByArrayLiteral {

    init(arrayLiteral elements: Element...) { self.init(elements) }

}



// MARK: : ExpressibleByDictionaryLiteral

extension KvOrderedDictionary : ExpressibleByDictionaryLiteral {

    init(dictionaryLiteral elements: (Key, Value)...) { self.init(elements) }

}



// MARK: : Equatable

extension KvOrderedDictionary : Equatable where Value : Equatable { }



// MARK: : Hashable

extension KvOrderedDictionary : Hashable where Value : Hashable {  }
