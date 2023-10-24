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
//  KvGridCellViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 27.11.2023.
//

// MARK: Auxiliaries

extension KvView {

    /// - Parameter transform: Argument is always non-nil.
    @inline(__always)
    @usableFromInline
    consuming func withModifiedGridCell(_ transform: (inout KvViewConfiguration.GridCell?) -> Void) -> some KvView {
        modified { configuration in
            if configuration.gridCell == nil {
                configuration.gridCell = .init()
            }
            transform(&configuration.gridCell)
            return nil
        }
    }

}



// MARK: Grid Layout Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func gridColumnAlignment(_ alignment: KvHorizontalAlignment) -> some KvView { withModifiedGridCell {
        $0!.gridColumnAlignment = alignment
    } }


    // TODO: DOC
    @inlinable
    public consuming func gridCellColumns(_ count: Int) -> some KvView { withModifiedGridCell {
        $0!.gridCellColumnSpan = count
    } }

}
