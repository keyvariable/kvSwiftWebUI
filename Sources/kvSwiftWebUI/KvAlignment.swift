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
//  KvAlignment.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 11.11.2023.
//

import kvCssKit



// MARK: - KvAlignment

public typealias Alignment = KvAlignment



// TODO: DOC
public struct KvAlignment : Equatable {

    // TODO: DOC
    public var horizontal: KvHorizontalAlignment
    // TODO: DOC
    public var vertical: KvVerticalAlignment



    // TODO: DOC
    @inlinable
    public init(horizontal: KvHorizontalAlignment, vertical: KvVerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }



    // MARK: Constants

    // TODO: DOC
    public static let topLeading = KvAlignment(horizontal: .leading, vertical: .top)

    // TODO: DOC
    public static let top = KvAlignment(horizontal: .center, vertical: .top)

    // TODO: DOC
    public static let topTrailing = KvAlignment(horizontal: .trailing, vertical: .top)

    // TODO: DOC
    public static let leading = KvAlignment(horizontal: .leading, vertical: .center)

    // TODO: DOC
    public static let center = KvAlignment(horizontal: .center, vertical: .center)

    // TODO: DOC
    public static let trailing = KvAlignment(horizontal: .trailing, vertical: .center)

    // TODO: DOC
    public static let bottomLeading = KvAlignment(horizontal: .leading, vertical: .bottom)

    // TODO: DOC
    public static let bottom = KvAlignment(horizontal: .center, vertical: .bottom)

    // TODO: DOC
    public static let bottomTrailing = KvAlignment(horizontal: .trailing, vertical: .bottom)

    // TODO: DOC
    public static let leadingFirstTextBaseline = KvAlignment(horizontal: .leading, vertical: .firstTextBaseline)

    // TODO: DOC
    public static let centerFirstTextBaseline = KvAlignment(horizontal: .center, vertical: .firstTextBaseline)

    // TODO: DOC
    public static let trailingFirstTextBaseline = KvAlignment(horizontal: .trailing, vertical: .firstTextBaseline)

    // TODO: DOC
    public static let leadingLastTextBaseline = KvAlignment(horizontal: .leading, vertical: .lastTextBaseline)

    // TODO: DOC
    public static let centerLastTextBaseline = KvAlignment(horizontal: .center, vertical: .lastTextBaseline)

    // TODO: DOC
    public static let trailingLastTextBaseline = KvAlignment(horizontal: .trailing, vertical: .lastTextBaseline)



    // MARK: Operations

    var cssBackgroundPosition: KvCssBackground.Position {
        .init(horizontal.cssBackgroundPosition, vertical.cssBackgroundPosition)
    }


    var cssObjectPosition: String {
        let rValue: String = switch (horizontal, vertical) {
        case (.leading, .center): "left"
        case (.trailing, .center): "right"
        case (.center, .top), (.center, .firstTextBaseline): "top"
        case (.center, .bottom), (.center, .lastTextBaseline): "botom"
        case (.center, .center): "center"
        case (.leading, .top), (.leading, .firstTextBaseline): "left top"
        case (.leading, .bottom),  (.leading, .lastTextBaseline):  "left bottom"
        case (.trailing, .top), (.trailing, .firstTextBaseline): "right top"
        case (.trailing, .bottom), (.trailing, .lastTextBaseline): "right bottom"
        }

        return "object-position:\(rValue)"
    }

}



// MARK: - KvHorizontalAlignment

public typealias HorizontalAlignment = KvHorizontalAlignment



// TODO: DOC
public enum KvHorizontalAlignment : Equatable {

    case leading, center, trailing


    // MARK: Operations

    var cssBackgroundPosition: KvCssBackground.Position.Horizontal {
        switch self {
        case .leading: .left
        case .center: .center
        case .trailing: .right
        }
    }

}



// MARK: - KvVerticalAlignment

public typealias VerticalAlignment = KvVerticalAlignment



// TODO: DOC
public enum KvVerticalAlignment : Equatable {

    case top, center, bottom
    case firstTextBaseline, lastTextBaseline



    // MARK: Operations

    var cssBackgroundPosition: KvCssBackground.Position.Vertical {
        switch self {
        case .center: .center
        case .bottom, .lastTextBaseline: .bottom
        case .firstTextBaseline, .top: .top
        }
    }

}
