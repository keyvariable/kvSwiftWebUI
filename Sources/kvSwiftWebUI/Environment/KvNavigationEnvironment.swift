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
//  KvNavigationEnvironment.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 16.01.2024.
//

// MARK: - \.navigationPath

extension KvEnvironmentValues {

    private struct NavigationPathKey : KvEnvironmentKey {

        static var defaultValue: KvNavigationPath { .empty }

    }


    // TODO: DOC
    public internal(set) var navigationPath: KvNavigationPath {
        get { self[NavigationPathKey.self] }
        set { self[NavigationPathKey.self] = newValue }
    }

}
