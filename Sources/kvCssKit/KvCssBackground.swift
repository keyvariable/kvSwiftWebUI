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
//  KvCssBackground.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 18.11.2023.
//

import Foundation



/// Representation of CSS background property.
public struct KvCssBackground {

    public var source: Source
    public var position: Position
    public var size: Size?
    public var `repeat`: Repeat



    @inlinable
    public init(source: Source, position: Position? = nil, size: Size? = nil, `repeat`: Repeat? = nil) {
        self.source = source
        self.position = position ?? .init(x: .percents(0), y: .percents(0))
        self.size = size
        self.repeat = `repeat` ?? .repeat
    }



    // MARK: Operations

    /// - Returns: String with CSS representation of the receiver.
    @inlinable
    public var css: String {
        let `repeat` = !`repeat`.isDefault ? " \(`repeat`.css) " : ""

        let positionAndSize: String = switch (position.isDefault, size) {
        case (_, .some(let size)):
            " \(position.css)/\(size.css)"
        case (false, nil):
            " \(position.css)"
        case (true, nil):
            ""
        }

        return "\(source.css)\(positionAndSize)\(`repeat`)"
    }



    // MARK: .Position

    public struct Position {

        public var x: Horizontal
        public var y: Vertical


        @inlinable
        public init(x: Horizontal, y: Vertical) {
            self.x = x
            self.y = y
        }


        @inlinable
        public init(_ x: Horizontal, _ y: Vertical) {
            self.init(x: x, y: y)
        }


        @inlinable
        public init(_ offset: KvCssLength) { self.init(x: offset, y: offset) }


        @inlinable
        public init(x: KvCssLength, y: KvCssLength) { self.init(x: .offset(x), y: .offset(y)) }


        // MARK: Fabrics

        public static let bottom: Self = .init(x: .center, y: .bottom)

        public static let center: Self = .init(x: .center, y: .center)

        public static let `left`: Self = .init(x: .left, y: .center)

        public static let right: Self = .init(x: .right, y: .center)

        public static let top: Self = .init(x: .center, y: .top)


        // MARK: Operations

        /// - Returns: String with CSS representation of the receiver.
        @inlinable
        public var css: String {
            switch (x, y) {
            case (.left, .center), (.left, .centerOffset):
                return "left"
            case (.center, .center), (.center, .centerOffset), (.centerOffset, .center), (.centerOffset, .centerOffset):
                return "center"
            case (.right, .center), (.right, .centerOffset):
                return "right"
            case (.center, .bottom), (.centerOffset, .bottom):
                return "bottom"
            case (.center, .top), (.centerOffset, .top):
                return "top"

            default:
                let x = x.css, y = y.css

                return x != y ? "\(x) \(y)" : x
            }
        }


        @inlinable
        public var isDefault: Bool {
            switch (x, y) {
            case (.zeroOffset, .zeroOffset): true
            default: false
            }
        }


        // MARK: .Horizontal

        public enum Horizontal : Equatable {

            case left(KvCssLength?), center, right(KvCssLength?)
            case offset(KvCssLength)


            // MARK: Fabrics

            public static let left: Self = .left(nil)

            public static let right: Self = .right(nil)

            public static let zeroOffset: Self = .offset(.percents(0))
            public static let centerOffset: Self = .offset(.percents(50))


            // MARK: Operations

            /// - Returns: String with CSS representation of the receiver.
            @inlinable
            public var css: String {
                switch self {
                case .center: "center"
                case .left(.none): "left"
                case .left(.some(let value)): "left \(value.css)"
                case .offset(let value): value.css
                case .right(.none): "right"
                case .right(.some(let value)): "right \(value.css)"
                }
            }

        }


        // MARK: .Vertical

        public enum Vertical : Equatable {

            case top(KvCssLength?), center, bottom(KvCssLength?)
            case offset(KvCssLength)


            // MARK: Fabrics

            public static let bottom: Self = .bottom(nil)

            public static let top: Self = .top(nil)

            public static let zeroOffset: Self = .offset(.percents(0))
            public static let centerOffset: Self = .offset(.percents(50))


            // MARK: Operations

            /// - Returns: String with CSS representation of the receiver.
            @inlinable
            public var css: String {
                switch self {
                case .bottom(.none): "bottom"
                case .bottom(.some(let value)): "bottom \(value.css)"
                case .center: "center"
                case .offset(let value): value.css
                case .top(.none): "top"
                case .top(.some(let value)): "top \(value.css)"
                }
            }

        }

    }



    // MARK: .Size

    public enum Size {

        case contain
        case cover
        case size(width: KvCssLength, height: KvCssLength)


        // MARK: Named Initializers

        public static let auto: Size = .size(width: .auto, height: .auto)


        @inlinable
        public static func size(_ value: KvCssLength) -> Size { .size(width: value, height: value) }


        // MARK: CSS

        @inlinable
        public var css: String {
            switch self {
            case .contain:
                return "contain"

            case .cover:
                return "cover"

            case .size(width: let width, height: let height):
                let width = width.css, height = height.css

                return width != height ? "\(width) \(height)" : width
            }
        }

    }



    // MARK: .Repeat

    public struct Repeat : Equatable {

        public var horizontal: Value
        public var vertical: Value


        @inlinable
        public init(horizontal: Value, vertical: Value) {
            self.horizontal = horizontal
            self.vertical = vertical
        }


        @inlinable
        public init(_ horizontal: Value, _ vertical: Value) {
            self.init(horizontal: horizontal, vertical: vertical)
        }


        @inlinable
        public init(_ value: Value) { self.init(horizontal: value, vertical: value) }


        // MARK: Fabrics

        public static let repeatX: Self = .init(.repeat, .noRepeat)

        public static let repeatY: Self = .init(.noRepeat, .repeat)

        public static let `repeat`: Self = .init(.repeat)

        public static let space: Self = .init(.space)

        public static let round: Self = .init(.round)

        public static let noRepeat: Self = .init(.noRepeat)


        // MARK: Operations

        /// - Returns: String with CSS representation of the receiver.
        @inlinable
        public var css: String {
            switch (horizontal, vertical) {
            case (.noRepeat, .noRepeat), (.repeat, .repeat), (.round, .round), (.space, .space):
                horizontal.css
            case (.repeat, .noRepeat):
                "repeat-x"
            case (.noRepeat, .repeat):
                "repeat-y"
            default:
                "\(horizontal.css) \(vertical.css)"
            }
        }


        @inlinable
        public var isDefault: Bool {
            switch (horizontal, vertical) {
            case (.repeat, .repeat): true
            default: false
            }
        }


        // MARK: .Value

        public enum Value : Equatable {

            case `repeat`, space, round, noRepeat


            // MARK: Operations

            /// - Returns: String with CSS representation of the receiver.
            @inlinable
            public var css: String {
                switch self {
                case .repeat: "repeat"
                case .space: "space"
                case .round: "round"
                case .noRepeat: "no-repeat"
                }
            }

        }

    }



    // MARK: .Source

    public enum Source : Equatable {

        case uri(String)


        // MARK: Fabrics

        @inlinable
        public static func url(_ url: URL) -> Self { .uri(url.absoluteString) }


        // MARK: Operations

        /// - Returns: String with CSS representation of the receiver.
        @inlinable
        public var css: String {
            switch self {
            case .uri(let uri):
                "url('\(uri)')"
            }
        }

    }

}
