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
//  KvEnvironmentValues.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

public typealias EnvironmentValues = KvEnvironmentValues



// TODO: DOC
public class KvEnvironmentValues {

    var parent: KvEnvironmentValues?



    init(parent: KvEnvironmentValues? = nil) {
        self.parent = parent
    }


    init(_ transform: (KvEnvironmentValues) -> Void) {
        transform(self)
    }



    private var container: [ObjectIdentifier : Any] = [:]



    // MARK: Frequently Used Properties

    var foregroundStyle: KvAnyShapeStyle? {
        get { _foregroundStyle ?? parent?.foregroundStyle }
        set { _foregroundStyle = newValue }
    }
    private var _foregroundStyle: KvAnyShapeStyle?


    var textStyle: KvFont.TextStyle? {
        get { _textStyle ?? parent?.textStyle }
        set { _textStyle = newValue }
    }
    private var _textStyle: KvFont.TextStyle?



    // MARK: Access

    public subscript<Key : KvEnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            container[ObjectIdentifier(key)].map { $0 as! Key.Value }
            ?? parent?[key]
            ?? key.defaultValue
        }
        set { container[ObjectIdentifier(key)] = newValue }
    }



    // MARK: Operations

    /// - Returns: New instance where parent reference points to the receiver.
    func descendant() -> KvEnvironmentValues { .init(parent: self) }

}
