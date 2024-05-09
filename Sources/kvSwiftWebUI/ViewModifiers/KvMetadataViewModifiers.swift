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
//  KvMetadataViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 07.05.2024.
//

// MARK: Metadata Modifiers

extension KvView {

    /// This modifier provides description metadata for the resulting navigation destination.
    ///
    /// If several views declare description metadata in a navigation destination then the first description is used and others are ignored.
    ///
    /// - SeeAlso: ``KvView/metadata(keywords:)-3w75u``.
    @inlinable
    public consuming func metadata(description: KvText) -> some KvView { mapConfiguration {
        $0!.metadataDescription = description
    } }


    /// An overload of ``KvView/metadata(description:)-8ai0v`` modifier.
    @inlinable
    public consuming func metadata(description: KvLocalizedStringKey) -> some KvView {
        metadata(description: KvText(description))
    }


    /// An overload of ``KvView/metadata(description:)-8ai0v`` modifier.
    @_disfavoredOverload
    @inlinable
    public consuming func metadata<S>(description: S) -> some KvView
    where S : StringProtocol
    {
        metadata(description: KvText(description))
    }



    /// This modifier provides keyword metadata for the resulting navigation destination.
    /// Usually keywords are used in SEO.
    ///
    /// If several views declare keyword metadata in a navigation destination then all the keywords are joined ignoring case and duplicates.
    /// In example below the resulting set of keywords is "A", "B", "c", "D":
    /// ```swift
    /// var body: some View {
    ///     Text("AB")
    ///         .metadata(keywords: "A", "B")
    ///     Text("ac")
    ///         .metadata(keywords: "a", "c")
    ///     Text("CD")
    ///         .metadata(keywords: "C", "D")
    /// }
    /// ```
    ///
    /// - SeeAlso: ``KvView/metadata(description:)-8ai0v``.
    public consuming func metadata<K>(keywords: K) -> some KvView
    where K : Sequence, K.Element == KvText
    { mapConfiguration {
        $0!.appendMetadataKeywords(keywords)
    } }


    /// An overload of ``KvView/metadata(keywords:)-3w75u`` modifier.
    @inlinable
    public consuming func metadata(keywords: KvText...) -> some KvView {
        metadata(keywords: keywords)
    }


    /// An overload of ``KvView/metadata(keywords:)-3w75u`` modifier.
    @_disfavoredOverload
    @inlinable
    public consuming func metadata<S>(keywords: S...) -> some KvView
    where S : StringProtocol
    {
        metadata(keywords: keywords.lazy.map { KvText.init($0) })
    }

}
