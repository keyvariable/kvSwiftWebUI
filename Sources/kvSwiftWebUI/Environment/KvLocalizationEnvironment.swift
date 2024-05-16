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
    /// - SeeAlso: ``KvEnvironmentValues/defaultBundle``.
    public internal(set) var localization: KvLocalization.Context {
        get {
            let context = self[LocalizationKey.self]!

            // TODO: Avoid redundant duplicate fetches.
            return switch defaultBundleIfExists {
            case .none:
                context
            case .some(let bundle):
                // The context is evaluated for the HTTP bundle's default bundle.
                // So if the default bundle is changed then content must be re-evaluated.
                context.with(primaryBundle: bundle)
            }
        }
        set { self[LocalizationKey.self] = newValue }
    }

}
