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
//  KvAppearanceViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

// MARK: Style Modifiers

extension KvView {

    // TODO: DOC
    /// - SeeAlso: ``background(_:)``.
    @inlinable
    public consuming func foregroundStyle<S : KvShapeStyle>(_ style: S) -> some KvView { mapConfiguration {
        $0!.foregroundStyle = style.eraseToAnyShapeStyle()
    } }

}



// MARK: Text Formatting Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func font(_ font: KvFont) -> some KvView { mapConfiguration {
        $0!.font = font
    } }


    // TODO: DOC
    @inlinable
    public consuming func multilineTextAlignment(_ textAlignment: KvTextAlignment) -> some KvView { mapConfiguration {
        $0!.multilineTextAlignment = textAlignment
    } }

}



// MARK: Text Style Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func textCase(_ textCase: KvText.Case?) -> some KvView { mapConfiguration {
        $0!.textCase = textCase
    } }

}



// MARK: Layout Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func fixedSize() -> some KvView { fixedSize(horizontal: true, vertical: true) }


    // TODO: DOC
    @inlinable
    public consuming func fixedSize(horizontal: Bool, vertical: Bool) -> some KvView { mapConfiguration {
        let fixedSize: KvViewConfiguration.FixedSize = switch (horizontal, vertical) {
        case (true, true): [ .horizontal, .vertical ]
        case (true, false): .horizontal
        case (false, true): .vertical
        case (false, false): [ ]
        }

        return $0!.fixedSize = fixedSize
    } }

}
