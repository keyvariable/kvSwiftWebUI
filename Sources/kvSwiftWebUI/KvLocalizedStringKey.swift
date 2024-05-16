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
//  KvLocalizedStringKey.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.10.2023.
//

import Foundation



public typealias LocalizedStringKey = KvLocalizedStringKey



// TODO: DOC
/// This type is designated to process strings as the localization keys.
///
/// ## String Interpolations
///
/// `KvLocalizedStringKey` supports initialization from string interpolation literals.
///
/// For example:
/// ```swift
/// // Localization key: "name: %@, age: %lld, height: %f meters".
/// Text("name: \("Ben"), age: \(27), height: \(1.75) meters")
///
/// // Localization key: "Current timestamp: %@".
/// Text("Current timestamp: \(Date())")
/// ```
///
/// See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
public struct KvLocalizedStringKey : Equatable, ExpressibleByStringInterpolation {

    @usableFromInline
    let value: Value


    @inlinable
    public init(_ value: String) { self.value = .final(value) }


    @usableFromInline
    init<S : StringProtocol>(_ value: S) {
        self.init(String(value))
    }



    // MARK: .Value

    @usableFromInline
    enum Value : Equatable {

        case final(String)
        case formatted(format: String, arguments: [StringInterpolation.Argument])

        
        // MARK: : Equatable

        @usableFromInline
        static func ==(lhs: Value, rhs: Value) -> Bool {
            switch lhs {
            case .final(let value):
                guard case .final(value) = rhs else { return false }
            case .formatted(format: let format, arguments: _):
                guard case .formatted(format: format, arguments: _) = rhs else { return false }
            }
            return true
        }

    }



    // MARK: : Equatable

    @inlinable
    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.value == rhs.value }



    // MARK: : ExpressibleByStringInterpolation

    @inlinable
    public init(stringLiteral value: String) { self.init(value) }


    @inlinable
    public init(stringInterpolation: StringInterpolation) {
        self.value = .formatted(format: stringInterpolation.format, arguments: stringInterpolation.arguments)
    }



    // MARK: .StringInterpolation

    public struct StringInterpolation : StringInterpolationProtocol {

        @usableFromInline
        var format: String = .init()
        @usableFromInline
        var arguments: [Argument] = .init()


        // MARK: .Argument

        @usableFromInline
        enum Argument {

            case cVarArg(CVarArg, format: String)
            case text(KvText)

            
            // MARK: Operations

            var format: String {
                switch self {
                case .cVarArg(_, format: let format): format
                case .text(_): "%@"
                }
            }

        }


        // MARK: .Constants

        @usableFromInline
        struct Constants {

            @usableFromInline
            static var formatInt: String {
#if arch(x86_64) || arch(arm64)
            "%lld"
#elseif arch(i386) || arch(arm)
            "%d"
#else
            assertionFailure("Unsupported architecture")
            return "%lld"
#endif
            }

            @usableFromInline
            static var formatUInt: String {
#if arch(x86_64) || arch(arm64)
            "%llu"
#elseif arch(i386) || arch(arm)
            "%u"
#else
            assertionFailure("Unsupported architecture")
            return "%llu"
#endif
            }

        }


        // MARK: : StringInterpolationProtocol

        @inlinable
        public init(literalCapacity: Int, interpolationCount: Int) {
            // - NOTE: Capacity of `format` is not reserved due to number of percent character is unknown.

            if interpolationCount > 0 {
                arguments.reserveCapacity(interpolationCount)
            }
        }


        @inlinable
        public mutating func appendLiteral(_ literal: StringLiteralType) {
            // Escaping %
            var substring = Substring(literal)
            while let index = substring.firstIndex(of: "%") {
                format.append(contentsOf: substring[..<index])
                format.append("%")

                substring = substring[index...]
            }
            format.append(contentsOf: substring)
        }


        @usableFromInline
        mutating func appendArgument(_ argument: Argument) {
            format.append(argument.format)
            arguments.append(argument)
        }


        @inlinable
        public mutating func appendInterpolation(_ value: CVarArg, format: String) {
            appendArgument(.cVarArg(value, format: format))
        }


        @inlinable
        public mutating func appendInterpolation(_ string: String) {
            appendArgument(.cVarArg(string, format: "%@"))
        }


        @inlinable
        public mutating func appendInterpolation<S : StringProtocol>(_ string: S) {
            appendInterpolation(String(string))
        }


        @inlinable
        public mutating func appendInterpolation(_ character: Character) {
            appendInterpolation(String(character))
        }


        @inlinable
        public mutating func appendInterpolation<T : CustomStringConvertible>(_ value: T) {
            appendInterpolation(String(describing: value))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string.
        ///     By default `"%lld"` or `"%d"` is used whether architecture is a 64-bit one.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Int, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? Constants.formatInt))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string.
        ///     By default `"%llu"` or `"%d"` is used whether architecture is a 64-bit one.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: UInt, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? Constants.formatUInt))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%lld"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Int64, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%lld"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%llu"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: UInt64, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%llu"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%d"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Int32, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%d"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%u"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: UInt32, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%u"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%d"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Int16, format: String? = nil) {
            appendInterpolation(numericCast(number) as Int32, format: format)
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%u"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: UInt16, format: String? = nil) {
            appendInterpolation(numericCast(number) as UInt32, format: format)
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%d"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Int8, format: String? = nil) {
            appendInterpolation(numericCast(number) as Int32, format: format)
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%u"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: UInt8, format: String? = nil) {
            appendInterpolation(numericCast(number) as UInt32, format: format)
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string.
        ///     By default `"%lld"` or `"%d"` is used whether architecture is a 64-bit one.
        ///
        /// - Note: Value is converted to `Int` type.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation<T>(_ number: T, format: String? = nil)
        where T : BinaryInteger & SignedInteger
        {
            appendInterpolation(numericCast(number) as Int, format: format)
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string.
        ///     By default `"%llu"` or `"%u"` is used whether architecture is a 64-bit one. 
        ///
        /// - Note: Value is converted to `UInt` type.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation<T>(_ number: T, format: String? = nil)
        where T : BinaryInteger & UnsignedInteger
        {
            appendInterpolation(numericCast(number) as UInt, format: format)
        }


#if arch(x86_64)
        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%Lg"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Float80, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%Lg"))
        }
#endif // arch(x86_64)


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%g"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Double, format: String? = nil) {
            appendArgument(.cVarArg(number, format: format ?? "%g"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%g"` is used.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation(_ number: Float, format: String? = nil) {
            appendArgument(.cVarArg(Double(number), format: format ?? "%g"))
        }


        /// - Parameter format: An optional format specifier to be used in the resulting format string. By default `"%g"` is used.
        ///
        /// - Note: Value is converted to `Double` type.
        ///
        /// - Note: Format strings and the arguments are passed to `String(format:locale:arguments)`.
        ///     See this [article](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/formatSpecifiers.html) for details.
        @inlinable
        public mutating func appendInterpolation<T : BinaryFloatingPoint>(_ number: T, format: String? = nil) {
            appendArgument(.cVarArg(Double(number), format: format ?? "%g"))
        }


        @inlinable
        public mutating func appendInterpolation(_ text: KvText) {
            appendArgument(.text(text))
        }

    }

}
