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
//  KvCssLength.swift
//  kvCssKit
//
//  Created by Svyatoslav Popov on 16.11.2023.
//

// TODO: Generalize expression system with handling of operator priority.
/// Representation of CSS [&lt;length&gt;](https://www.w3.org/TR/css-values-3/#lengths)
/// and [&lt;length-percentage&gt;](https://www.w3.org/TR/css-values-3/#percentages) types.
public indirect enum KvCssLength : Hashable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {

    case auto
    case max(KvCssLength, KvCssLength)
    case min(KvCssLength, KvCssLength)
    case scaled(Double, KvCssLength)
    case sub(KvCssLength, KvCssLength)
    case sum(KvCssLength, KvCssLength)
    case value(Double, Unit)



    @inlinable
    public init(_ value: Double, _ unit: Unit = .pixels) {
        self = .value(value, unit)
    }


    @inlinable
    public init<T : BinaryFloatingPoint>(_ value: T, _ unit: Unit = .pixels) { self.init(Double(value), unit) }



    // MARK: Constants

    /// An infinity length.
    public static let infinity: Self = .value(.infinity, .pixels)



    // MARK: Fabrics

    /// Shorthand for `.value(value, .characterAdvance)`.
    ///
    /// - SeeAlso: ``Unit/characterAdvance``.
    @inlinable
    public static func ch(_ value: Double) -> Self { .value(value, .characterAdvance) }

    /// - Returns: `.value(value, .fontSize)`.
    ///
    /// - SeeAlso: ``Unit/fontSize``.
    @inlinable
    public static func em(_ value: Double) -> Self { .value(value, .fontSize) }

    /// - Returns: `.value(value, .fontXHeight)`.
    ///
    /// - SeeAlso: ``Unit/fontXHeight``.
    @inlinable
    public static func ex(_ value: Double) -> Self { .value(value, .fontXHeight) }

    /// - Returns: `.value(value, .percents)`.
    ///
    /// - SeeAlso: ``Unit/percents``.
    @inlinable
    public static func percents(_ value: Double) -> Self { .value(value, .percents) }

    /// - Returns: `.value(value, .points)`.
    ///
    /// - SeeAlso: ``Unit/points``.
    @inlinable
    public static func pt(_ value: Double) -> Self { .value(value, .points) }

    /// - Returns: `.value(value, .pixels)`.
    ///
    /// - SeeAlso: ``Unit/pixels``.
    @inlinable
    public static func px(_ value: Double) -> Self { .value(value, .pixels) }

    /// - Returns: `.value(value, .rootFontSize)`.
    ///
    /// - SeeAlso: ``Unit/rootFontSize``.
    @inlinable
    public static func rem(_ value: Double) -> Self { .value(value, .rootFontSize) }

    /// - Returns: `.value(value, .viewportHeight_100)`.
    ///
    /// - SeeAlso: ``Unit/viewportHeight_100``.
    @inlinable
    public static func vh(_ value: Double) -> Self { .value(value, .viewportHeight_100) }

    /// - Returns: `.value(value, .viewportMaximum_100)`.
    ///
    /// - SeeAlso: ``Unit/viewportMaximum_100``.
    @inlinable
    public static func vmax(_ value: Double) -> Self { .value(value, .viewportMaximum_100) }

    /// - Returns: `.value(value, .viewportMinimum_100)`.
    ///
    /// - SeeAlso: ``Unit/viewportMinimum_100``.
    @inlinable
    public static func vmin(_ value: Double) -> Self { .value(value, .viewportMinimum_100) }

    /// - Returns: `.value(value, .viewportWidth_100)`.
    ///
    /// - SeeAlso: ``Unit/viewportWidth_100``.
    @inlinable
    public static func vw(_ value: Double) -> Self { .value(value, .viewportWidth_100) }



    // MARK: : ExpressibleByFloatLiteral

    @inlinable
    public init(floatLiteral value: FloatLiteralType) { self = .value(value, .pixels) }



    // MARK: : ExpressibleByIntegerLiteral

    @inlinable
    public init(integerLiteral value: IntegerLiteralType) { self = .value(Double(value), .pixels) }



    // MARK: Operations

    /// - Returns: String with CSS representation of the receiver.
    @inlinable
    public var css: String {
        let description = Description(of: self)

        return (!description.flags().contains(.isExpression)
                ? description.rValue()
                : "calc(\(description.rValue()))")
    }



    // MARK: Operators

    @inlinable
    public static func +(lhs: Self, rhs: Self) -> Self { .sum(lhs, rhs) }


    @inlinable
    public static func -(lhs: Self, rhs: Self) -> Self { .sub(lhs, rhs) }


    @inlinable
    public static func *(scale: Double, value: Self) -> Self { .scaled(scale, value) }

    @inlinable
    public static func *<T : BinaryFloatingPoint>(scale: T, value: Self) -> Self { .scaled(Double(scale), value) }

    @inlinable
    public static func *<T : BinaryInteger>(scale: T, value: Self) -> Self { .scaled(Double(scale), value) }


    @inlinable
    public static func *(value: Self, scale: Double) -> Self { .scaled(scale, value) }

    @inlinable
    public static func *<T : BinaryFloatingPoint>(value: Self, scale: T) -> Self { .scaled(Double(scale), value) }

    @inlinable
    public static func *<T : BinaryInteger>(value: Self, scale: T) -> Self { .scaled(Double(scale), value) }


    @inlinable
    public static func /(value: Self, scale: Double) -> Self { .scaled(1.0 / scale, value) }

    @inlinable
    public static func /<T : BinaryFloatingPoint>(value: Self, scale: T) -> Self { .scaled(1.0 / Double(scale), value) }

    @inlinable
    public static func /<T : BinaryInteger>(value: Self, scale: T) -> Self { .scaled(1.0 / Double(scale), value) }



    // MARK: .Unit

    public enum Unit : Hashable {

        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#ch ).
        case characterAdvance
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#em ).
        case fontSize
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#ex ).
        case fontXHeight
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#percentage-value ).
        case percents
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#px ).
        case pixels
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#pt ).
        case points
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#rem ).
        case rootFontSize
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#vh ).
        case viewportHeight_100
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#vmax ).
        case viewportMaximum_100
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#vmin ).
        case viewportMinimum_100
        /// [css values and units module level 3](https://www.w3.org/TR/css-values-3/#vw ).
        case viewportWidth_100


        // MARK: Operations

        /// - Returns: String with CSS representation of the receiver.
        @inlinable
        public var css: String {
            switch self {
            case .characterAdvance: "ch"
            case .fontSize: "em"
            case .fontXHeight: "ex"
            case .percents: "%"
            case .pixels: "px"
            case .points: "pt"
            case .rootFontSize: "rem"
            case .viewportHeight_100: "vh"
            case .viewportMaximum_100: "vmax"
            case .viewportMinimum_100: "vmin"
            case .viewportWidth_100: "vw"
            }
        }

    }



    // MARK: .Description

    @usableFromInline
    struct Description {

        @usableFromInline
        let rValue: () -> String

        @usableFromInline
        let value: () -> (value: Double, unit: Unit)?

        @usableFromInline
        let flags: () -> Flags



        @usableFromInline
        init(of value: KvCssLength) {
            switch value {
            case .auto:
                self.init("auto")

            case .max(let lhs, let rhs):
                self.init(maximumOf: lhs, rhs)

            case .min(let lhs, let rhs):
                self.init(minimumOf: lhs, rhs)

            case .scaled(let scale, let length):
                self.init(length, scaledBy: scale)

            case .sub(let lhs, let rhs):
                self.init(subOf: lhs, rhs)

            case .sum(let lhs, let rhs):
                self.init(sumOf: lhs, rhs)

            case .value(let value, let unit):
                self.init(value: value, unit: unit)
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(_ rValue: @autoclosure @escaping () -> String,
             value: @autoclosure @escaping () -> (Double, Unit)? = nil,
             flags: @autoclosure @escaping () -> Flags = [ ]
        ) {
            self.rValue = rValue
            self.value = value
            self.flags = flags
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(maximumOf lhs: KvCssLength, _ rhs: KvCssLength) {
            let ld = Description(of: lhs), rd = Description(of: rhs)
            let lf = ld.flags().intersection(.valueMask), rf = rd.flags().intersection(.valueMask)

            if lf.contains(.zero), !rf.isEmpty {
                self = rd
            }
            else if rf.contains(.zero), !lf.isEmpty {
                self = ld
            }
            else if let lv = ld.value(), let rv = rd.value(), lv.unit == rv.unit {
                self.init(value: Swift.max(lv.value, rv.value), unit: lv.unit)
            }
            else {
                self.init(
                    "max(\(ld.rValue()),\(rd.rValue()))",
                    flags: !(lf.isEmpty || rf.isEmpty) ? [ .isExpression, .nonNegative ] : .isExpression    // - NOTE: Conditions above are taken into account.
                )
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(minimumOf lhs: KvCssLength, _ rhs: KvCssLength) {
            let ld = Description(of: lhs), rd = Description(of: rhs)
            let lf = ld.flags().intersection(.valueMask), rf = rd.flags().intersection(.valueMask)

            if lf.contains(.zero), !rf.isEmpty {
                self = ld
            }
            else if rf.contains(.zero), !lf.isEmpty {
                self = rd
            }
            else if let lv = ld.value(), let rv = rd.value(), lv.unit == rv.unit {
                self.init(value: Swift.min(lv.value, rv.value), unit: lv.unit)
            }
            else {
                self.init(
                    "min(\(ld.rValue()),\(rd.rValue()))",
                    flags: !(lf.isEmpty || rf.isEmpty) ? [ .isExpression, .nonNegative ] : .isExpression    // - NOTE: Conditions above are taken into account.
                )
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(_ length: KvCssLength, scaledBy scale: Double) {
            switch length {
            case .value(let value, let unit):
                self.init(value: value * scale, unit: unit)

            default:
                guard abs(scale) >= 1e-4 else {
                    self.init(value: 0, unit: .pixels)
                    return
                }

                let ld = Description(of: length)
                let lf = ld.flags()
                guard !lf.contains(.zero) else {
                    self.init(of: length)
                    return
                }

                let rhs = lf.contains(.isExpression) ? "(\(ld.rValue()))" : ld.rValue()
                let flags = scale > 0 ? lf : lf.symmetricDifference(.nonNegative)   // - NOTE: Conditions above are taken into account.

                self.init("\(scale) * \(rhs)", flags: flags)
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(subOf lhs: KvCssLength, _ rhs: KvCssLength) {
            let rd = Description(of: rhs)
            let rf = rd.flags()
            guard !rf.contains(.zero) else {
                self.init(of: lhs)
                return
            }

            let ld = Description(of: lhs)
            let lf = ld.flags()
            guard !lf.contains(.zero) else {
                self.init(rf.contains(.isExpression) ? "-(\(rd.rValue()))" : "-\(rd.rValue())",
                          flags: rf.symmetricDifference(.nonNegative))
                return
            }

            switch (ld.value(), rd.value()) {
            case (.some(let lhs), .some(let rhs)) where lhs.unit == rhs.unit:
                // Values having common unit are just subtracted.
                self.init(value: lhs.value - rhs.value, unit: lhs.unit)

            default:
                self.init("\(ld.rValue()) - \(rf.contains(.isExpression) ? "(\(rd.rValue()))" : rd.rValue())",
                          flags: .isExpression)
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(sumOf lhs: KvCssLength, _ rhs: KvCssLength) {
            let rd = Description(of: rhs)
            let rf = rd.flags()
            guard !rf.contains(.zero) else {
                self.init(of: lhs)
                return
            }

            let ld = Description(of: lhs)
            let lf = ld.flags()
            guard !lf.contains(.zero) else {
                self.init(of: rhs)
                return
            }

            switch (ld.value(), rd.value()) {
            case (.some(let lhs), .some(let rhs)) where lhs.unit == rhs.unit:
                // Values having common unit are just added.
                self.init(value: lhs.value + rhs.value, unit: lhs.unit)

            default:
                self.init(
                    "\(ld.rValue()) + \(rd.rValue())",
                    flags: lf.intersection(rf)
                        .intersection(.valueMask)
                        .union(.isExpression)
                )
            }
        }


        /// - Important: It's an auxiliary. Use ``init(of:)`` instead.
        @usableFromInline
        init(value: Double, unit: Unit) {
            self.init(
                // TODO: Omit unit for zero values conditionally whether value is inside a `calc` expression.
                { abs(value) >= 1e-4 ? "\(String(format: "%g", value))\(unit.css)" : "0\(unit.css)" }(),
                value: (value, unit),
                flags: {
                    if value >= 1e-4 { .nonNegative }
                    else if value > -1e-4 { [ .zero, .nonNegative ] }
                    else { [ ] }
                }()
            )
        }



        // MARK: .Flags

        @usableFromInline
        struct Flags : OptionSet {

            @usableFromInline
            static let isExpression = Self(rawValue: 1 << 0)

            @usableFromInline
            static let zero = Self(rawValue: 1 << 1)
            @usableFromInline
            static let nonNegative = Self(rawValue: 1 << 2)


            @usableFromInline
            static let valueMask: Self = [ .zero, .nonNegative ]


            // MARK: : OptionSet

            @usableFromInline let rawValue: UInt

            @usableFromInline init(rawValue: UInt) { self.rawValue = rawValue }
        }

    }

}



// MARK: Global functions

@inlinable
public func max(_ lhs: KvCssLength, _ rhs: KvCssLength) -> KvCssLength { .max(lhs, rhs) }


@inlinable
public func min(_ lhs: KvCssLength, _ rhs: KvCssLength) -> KvCssLength { .min(lhs, rhs) }
