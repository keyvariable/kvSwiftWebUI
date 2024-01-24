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
//  KvEnvironment.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

public typealias Environment = KvEnvironment



// MARK: - KvEnvironmentProtocol

/// This protocol is used to enumerate properties with ``KvEnvironment`` wrapper.
protocol KvEnvironmentProtocol : AnyObject {

    var keyPath: PartialKeyPath<KvEnvironmentValues> { get }

    var source: KvEnvironmentValues.Node! { get set }

}



// MARK: - KvEnvironment

// TODO: DOC
@propertyWrapper
public class KvEnvironment<Value> : KvEnvironmentProtocol {

    let keyPath: PartialKeyPath<KvEnvironmentValues>

    weak var source: KvEnvironmentValues.Node!

    let valueGetter: (borrowing KvEnvironmentValues.Node) -> Value



    public init(_ keyPath: KeyPath<KvEnvironmentValues, Value>) {
        self.keyPath = keyPath
        valueGetter = { $0.values[keyPath: keyPath] }
    }



    public var wrappedValue: Value { valueGetter(source) }

}
