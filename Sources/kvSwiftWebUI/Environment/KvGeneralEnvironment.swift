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
//  KvGeneralEnvironment.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.04.2024.
//

import Foundation



// MARK: - \.defaultBundle

extension KvEnvironmentValues {

    private struct DefaultBundleKey : KvEnvironmentKey {

        static var defaultValue: Bundle { .main }

    }


    /// Default bundle to use when `nil` bundle is passed as an argument.
    ///
    /// Provided value is used instead of ``KvHttpBundle/Configuration/defaultBundle`` in configuration of HTTP bundle.
    ///
    /// - SeeAlso: ``KvView/defaultBundle(_:)``.
    public var defaultBundle: Bundle {
        get { self[DefaultBundleKey.self] }
        set { self[DefaultBundleKey.self] = newValue }
    }


    var defaultBundleIfExists: Bundle? {
        self.value(forKey: DefaultBundleKey.self)
    }

}
