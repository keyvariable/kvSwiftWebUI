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
//  KvGeneralViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 17.02.2024.
//

import Foundation



// MARK: General Modifiers

extension KvView {

    /// This modifier chages bundle to use as default value for optional arguments of `Bundle?` type.
    /// By default ``KvHttpBundle/Configuration/defaultBundle`` bundle is used.
    ///
    /// It is often necessary to pass  `.module` as an argument due to the specifics of cross-platform development on Swift.
    /// This modifier changes the default value of `Bundle?` arguments in *kvSwiftWebUI*.
    /// Also this modifier makes possible to create public implementations of views in separate modules with their own resources.
    ///
    /// ```swift
    /// VStack {
    ///     Image("a.png")
    ///     Image("b.png")
    ///     Text("Localized text")
    /// }
    /// .defaultBundle(.module)
    /// ```
    ///
    /// - SeeAlso: ``KvHttpBundle/Configuration/defaultBundle``, ``KvEnvironmentValues/defaultBundle``.
    @inlinable
    public consuming func defaultBundle(_ bundle: Bundle) -> some KvView {
        environment(\.defaultBundle, bundle)
    }

}



// MARK: Legacy

extension KvView {

    @available(*, deprecated, renamed: "defaultBundle(_:)", message: "Use `defaultBundle(_:)` instead")
    public consuming func localizationBundle(_ bundle: Bundle?) -> some KvView { defaultBundle(bundle ?? .main) }

}
