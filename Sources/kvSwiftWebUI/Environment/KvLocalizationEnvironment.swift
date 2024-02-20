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
//  KvLocalizationEnvironment.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 11.02.2024.
//

import Foundation



// MARK: - \.localization

extension KvEnvironmentValues {

    private struct LocalizationKey : KvEnvironmentKey {

        static var defaultValue: KvLocalization.Context? { nil }

    }


    /// Current localization context.
    ///
    /// Below is an example of common usage:
    /// ```swift
    /// struct HelloView : View {
    ///     @Environment(\.localization) private var localization
    ///
    ///     var body: some View {
    ///         let hello = localization.string(forKey: "hello!")
    ///         Text(verbatim: hello.uppercased())
    ///     }
    /// }
    /// ```
    ///
    /// - Note: ``Text`` view supports localization so in most cases there is no need to access localization context.
    ///
    /// - SeeAlso: ``KvEnvironmentValues/localizationBundle``.
    public internal(set) var localization: KvLocalization.Context {
        get { self[LocalizationKey.self]! }
        set { self[LocalizationKey.self] = newValue }
    }

}



// MARK: - \.localizationBundle

extension KvEnvironmentValues {

    private struct LocalizationBundleKey : KvEnvironmentKey {

        static var defaultValue: Bundle? { nil }

    }


    /// Default localization bundle.
    ///
    /// If provided, then the value is used instead of ``KvHttpBundle/Configuration/localizationBundle`` in configuration of HTTP bundle.
    ///
    /// - SeeAlso: ``KvView/localizationBundle(_:)``.
    public var localizationBundle: Bundle? {
        get { self[LocalizationBundleKey.self] }
        set { self[LocalizationBundleKey.self] = newValue }
    }

}
