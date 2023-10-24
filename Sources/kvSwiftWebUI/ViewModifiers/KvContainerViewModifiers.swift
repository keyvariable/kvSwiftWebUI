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
//  KvContainerViewModifiers.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 28.11.2023.
//

import kvCssKit



// MARK: Auxiliaries

extension KvView {

    /// - Parameter transform: Argument is always non-nil.
    @inline(__always)
    @usableFromInline
    consuming func withModifiedContainer(_ transform: (inout KvViewConfiguration.Container?) -> KvViewConfiguration.Container?) -> some KvView {
        modified { configuration in
            if configuration.container == nil {
                configuration.container = .init()
            }
            return transform(&configuration.container).map {
                KvViewConfiguration(container: $0)
            }
        }
    }

}



// MARK: Style Modifiers

extension KvView {

    // TODO: DOC
    /// - SeeAlso: ``foregroundStyle(_:)``.
    @inlinable
    public consuming func background<S : KvShapeStyle>(_ style: S) -> some KvView { withModifiedContainer {
        $0!.modify(background: style.eraseToAnyShapeStyle())
    } }

}



// MARK: Layout Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func padding(_ inset: KvCssLength) -> some KvView {
        padding(KvCssEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset))
    }


    // TODO: DOC
    @inlinable
    public consuming func padding(_ edges: KvCssEdgeInsets.Edge.Set = .all, _ inset: KvCssLength? = nil) -> some KvView { withModifiedContainer {
        $0!.modify(paddingBlock: { padding in
            return .sum(padding, KvCssEdgeInsets(edges, inset.map { .max(0.0, $0) } ?? KvDefaults.padding))
        })
    } }


    // TODO: DOC
    @inlinable
    public consuming func padding(_ insets: KvCssEdgeInsets) -> some KvView { withModifiedContainer {
        $0!.modify(padding: insets)
    } }


    // TODO: DOC
    @inlinable
    public consuming func frame(width: KvCssLength? = nil, height: KvCssLength? = nil, alignment: KvAlignment = .center) -> some KvView {
        withModifiedContainer {
            typealias Size = KvViewConfiguration.Container.Frame.Size

            return $0!.modify(frame: .init(width: .init(ideal: width), height: .init(ideal: height), alignment: alignment))
        }
    }


    // TODO: DOC
    /// - Parameter idealWidth: It's ignored. It's provided just for compatibility reasons.
    /// - Parameter idealHeight: It's ignored. It's provided just for compatibility reasons.
    @inlinable
    public consuming func frame(minWidth: KvCssLength? = nil, idealWidth: KvCssLength? = nil, maxWidth: KvCssLength? = nil,
                                minHeight: KvCssLength? = nil, idealHeight: KvCssLength? = nil, maxHeight: KvCssLength? = nil,
                                alignment: KvAlignment = .center
    ) -> some KvView {
        withModifiedContainer {
            typealias Size = KvViewConfiguration.Container.Frame.Size

            let width = Size(minimum: minWidth, ideal: idealWidth, maximum: maxWidth)
            let height = Size(minimum: minHeight, ideal: idealHeight, maximum: maxHeight)

            return $0!.modify(frame: .init(width: width, height: height, alignment: alignment))
        }
    }

}



// MARK: Shape Modifiers

extension KvView {

    // TODO: DOC
    @inlinable
    public consuming func clipShape<S : Shape>(_ shape: S) -> some View { withModifiedContainer {
        $0!.modify(clipShape: shape.clipShape)
    } }

}
