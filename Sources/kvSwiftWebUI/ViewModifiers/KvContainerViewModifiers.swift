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



// MARK: Style Modifiers

extension KvView {

    /// This modifier changes background of current view container.
    ///
    /// As order of view modifications matters, in example below the result will differ:
    /// ```swift
    /// Text("1").background(.blue).padding()
    /// Text("2").padding().background(.green)
    /// ```
    /// Blue background is applied to exact frame of label, but green background is applied to label 2 including it's padding.
    /// It's due to label 2 is placed into a container having default padding first, then green background is applied to the container.
    /// Whereas blue background is applied to label 1 first, then the result is placed into a container having default padding.
    ///
    /// First encountered suitable background is used as background of `<body>` tag for each navigation destination.
    /// Most browsers use this background to fill entire viewport.
    ///
    /// - SeeAlso: ``foregroundStyle(_:)``.
    @inlinable
    public consuming func background<S : KvShapeStyle>(_ style: S) -> some KvView { mapConfiguration {
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
    public consuming func padding(_ edges: KvCssEdgeInsets.Edge.Set = .all, _ inset: KvCssLength? = nil) -> some KvView { mapConfiguration {
        $0!.modify(paddingBlock: { padding in
            return .sum(padding, KvCssEdgeInsets(edges, inset.map { .max(0.0, $0) } ?? KvDefaults.padding))
        })
    } }


    // TODO: DOC
    @inlinable
    public consuming func padding(_ insets: KvCssEdgeInsets) -> some KvView { mapConfiguration {
        $0!.modify(padding: insets)
    } }


    /// This modifier places the view into a container having given *width* and *height*. The container aligns the view using given *alignment*.
    @inlinable
    public consuming func frame(width: KvCssLength? = nil, height: KvCssLength? = nil, alignment: KvAlignment = .center) -> some KvView {
        mapConfiguration {
            typealias Size = KvViewConfiguration.Frame.Size

            return $0!.modify(frame: .init(width: .init(ideal: width), height: .init(ideal: height), alignment: alignment))
        }
    }


    /// This modifier places the view into a container having given dimensions. The container aligns the view using given *alignment*.
    ///
    /// - Note: *maxWidth* and *maxHeight* can be equal to `.infinity`. In this case container fills available space when possible.
    @inlinable
    public consuming func frame(minWidth: KvCssLength? = nil, idealWidth: KvCssLength? = nil, maxWidth: KvCssLength? = nil,
                                minHeight: KvCssLength? = nil, idealHeight: KvCssLength? = nil, maxHeight: KvCssLength? = nil,
                                alignment: KvAlignment = .center
    ) -> some KvView {
        mapConfiguration {
            typealias Size = KvViewConfiguration.Frame.Size

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
    public consuming func clipShape<S : Shape>(_ shape: S) -> some View { mapConfiguration {
        $0!.modify(clipShape: shape.clipShape)
    } }

}
