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
//  KvScriptViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 02.02.2024.
//

import Foundation



// MARK: Script-related Modifiers

extension KvView {

    /// This modifier associates given script resource with the receiver.
    ///
    /// Scripts are accumulated and passed to HTML builder.
    ///
    /// Below is a simple example of embedded and referenced scrips:
    /// ```swift
    /// EmptyView()
    ///     .script("window.alert('Hello!')")
    ///     .script(at: Bundle.module.url(
    ///         forResource: "SomeScript",
    ///         withExtension: "js"
    ///     )!)
    /// ```
    @inlinable
    public consuming func script(_ resource: KvScriptResource) -> some KvView { mapConfiguration { configuration -> Void in
        if configuration!.scriptResources?.insert(resource) == nil {
            configuration!.scriptResources = [ resource ]
        }
    } }


    /// This modifier associates a script at given URL with the receiver.
    ///
    /// Scripts are accumulated and passed to HTML builder.
    ///
    /// Example:
    /// ```swift
    /// EmptyView()
    ///     .script(at: Bundle.module.url(
    ///         forResource: "SomeScript",
    ///         withExtension: "js"
    ///     )!)
    /// ```
    @inlinable
    public consuming func script(at url: URL) -> some KvView { script(KvScriptResource.url(url)) }


    /// This modifier associates a script with given source code.
    ///
    /// Scripts are accumulated and passed to HTML builder.
    ///
    /// Example:
    /// ```swift
    /// EmptyView()
    ///     .script("window.alert('Hello!')")
    /// ```
    @inlinable
    public consuming func script(_ sourceCode: String) -> some KvView { script(KvScriptResource.sourceCode(sourceCode)) }

}
