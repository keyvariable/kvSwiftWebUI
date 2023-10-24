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
//  KvEnvironmentViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

// MARK: Auxiliaries

extension KvView {

    /// - Parameter transform: Argument is always non-nil.
    @inline(__always)
    @usableFromInline
    consuming func withModifiedEnvironment(_ transform: (inout KvEnvironmentValues?) -> Void) -> some KvView {
        modified { configuration in
            if configuration.environment == nil {
                configuration.environment = .init()
            }
            transform(&configuration.environment)
            return nil
        }
    }

}



// MARK: Environment Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func environment<T>(_ keyPath: WritableKeyPath<EnvironmentValues, T>, _ value: T) -> some KvView {
        withModifiedEnvironment {
            $0![keyPath: keyPath] = value
        }
    }

}
