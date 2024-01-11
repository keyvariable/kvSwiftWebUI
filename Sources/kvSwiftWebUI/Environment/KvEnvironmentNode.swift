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
//  KvEnvironmentNode.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 06.01.2024.
//

/// It's used to cascade environment containers.
class KvEnvironmentNode {

    let parent: KvEnvironmentNode?

    let values: KvEnvironmentValues



    init(parent: KvEnvironmentNode? = nil, values: KvEnvironmentValues) {
        self.parent = parent
        self.values = values
    }



    // MARK: Access

    subscript<Value>(keyPath: KeyPath<KvEnvironmentValues, Value?>) -> Value? {
        firstResult { $0[keyPath: keyPath] }
    }


    subscript<Value>(viewConfiguration keyPath: KeyPath<KvEnvironmentValues.ViewConfiguration, Value?>) -> Value? {
        firstResult { $0[viewConfiguration: keyPath] }
    }


    subscript<Key : KvEnvironmentKey>(key: Key.Type) -> Key.Value {
        firstResult { $0[key] } ?? key.defaultValue
    }



    // MARK: Operations

    /// - Returns: New instance where parent reference points to the receiver.
    func descendant(values: KvEnvironmentValues) -> KvEnvironmentNode { .init(parent: self, values: values) }


    private func firstResult<T>(of block: (borrowing KvEnvironmentValues) -> T?) -> T? {
        if let value = block(values) {
            return value
        }

        do {
            var container = self

            while let next = container.parent {
                if let value = block(next.values) {
                    return value
                }

                container = next
            }
        }

        return nil
    }

}
