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
//  KvEnvironmentValues.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 21.11.2023.
//

import kvCssKit



public typealias EnvironmentValues = KvEnvironmentValues



// TODO: DOC
public struct KvEnvironmentValues {

    var viewConfiguration: ViewConfiguration?



    init() { }


    init(_ viewConfiguration: ViewConfiguration?) {
        self.viewConfiguration = viewConfiguration
    }


    init(_ transform: (inout Self) -> Void) {
        transform(&self)
    }



    private var container: [ObjectIdentifier : Any] = [:]



    // MARK: Access

    subscript<Key : KvEnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            container[ObjectIdentifier(key)].map { $0 as! Key.Value }
            ?? key.defaultValue
        }
        set { container[ObjectIdentifier(key)] = newValue }
    }


    subscript<Value>(viewConfiguration keyPath: KeyPath<ViewConfiguration, Value?>) -> Value? {
        viewConfiguration?[keyPath: keyPath]
    }

}



// MARK: View Configuration

extension KvEnvironmentValues {

    public var font: KvFont? { viewConfiguration?.font }

    public var foregroundStyle: KvAnyShapeStyle? { viewConfiguration?.foregroundStyle }

    public var multilineTextAlignment: KvTextAlignment? { viewConfiguration?.multilineTextAlignment }

    public var textCase: KvText.Case? { viewConfiguration?.textCase }



    // MARK: .ViewConfiguration

    @usableFromInline
    struct ViewConfiguration {

        private(set) var navigationDestinations: NavigationDestinations?
        

        init() { }


        init(_ transform: (inout Self) -> Void) {
            transform(&self)

            // - NOTE: It's possible to change constrained properties via private code.
            resetConstraints()
        }


        private var regularValues: [RegularKey : Any] = [:]
        private var constrainedValues: [ConstrainedKey : Any] = [:]

        private var constraints: Constraints = [ ]


        // MARK: .RegularKey

        /// Keys for properties having no constaints with other properties.
        enum RegularKey : Hashable {
            case fixedSize
            case font
            case foregroundStyle
            case gridCellColumnSpan
            case gridColumnAlignment
            case multilineTextAlignment
            case navigationTitle
            case textCase
        }


        // MARK: .ConstrainedKey

        /// Keys for properties having constaints with other properties. E.g. background can't be changed when padding is set.
        enum ConstrainedKey : Hashable {
            case background
            case clipShape
            case frame
            case padding
        }


        // MARK: .Constraints

        private struct Constraints : OptionSet {

            static let immutablePadding = Self(rawValue: 1 << 0)
            static let immutableFrame = Self(rawValue: 1 << 1)
            static let immutableBackground = Self(rawValue: 1 << 2)

            let rawValue: UInt

        }


        // MARK: Fabrics

        static func merged(_ addition: Self?, over base: Self?) -> KvMergeResult<Self?> {
            guard let addition else { return .merged(base) }
            guard var result = base else { return .merged(addition) }

            // Constrained values.
            // - IMPORTANT: Order of modifications matters.
            guard addition.padding == nil || result.modify(padding: addition.padding!) == nil,
                  addition.frame == nil || result.modify(frame: addition.frame!) == nil,
                  addition.background == nil || result.modify(background: addition.background!) == nil,
                  addition.clipShape == nil || result.modify(clipShape: addition.clipShape!) == nil
            else { return .incompatibility }

            // Regular values.
            addition.regularValues.forEach { (key, value) in
                switch key {
                case .fixedSize:
                    result.fixedSize = .union(result.fixedSize, Self.cast(value, as: \.fixedSize))
                case .font, .foregroundStyle, .gridCellColumnSpan, .gridColumnAlignment, .multilineTextAlignment, .navigationTitle,
                        .textCase:
                    result.regularValues[key] = value
                }
            }

            return .merged(result)
        }


        // MARK: Subscripts

        private subscript<T>(key: RegularKey) -> T? {
            get { regularValues[key].map { $0 as! T } }
            set { regularValues[key] = newValue }
        }


        private subscript<T>(key: ConstrainedKey) -> T? {
            get { constrainedValues[key].map { $0 as! T } }
            set { constrainedValues[key] = newValue }
        }


        // MARK: Properties

        /// Use ``modify(background:)`` to change the value.
        private(set) var background: KvAnyShapeStyle? { get { self[.background] } set { self[.background] = newValue } }

        /// Use ``modify(clipShape:)`` to change the value.
        private(set) var clipShape: KvClipShape? { get { self[.clipShape] } set { self[.clipShape] = newValue } }

        @usableFromInline
        var fixedSize: FixedSize? { get { self[.fixedSize] } set { self[.fixedSize] = newValue } }

        @usableFromInline
        var font: KvFont? { get { self[.font] } set { self[.font] = newValue } }

        @usableFromInline
        var foregroundStyle: KvAnyShapeStyle? { get { self[.foregroundStyle] } set { self[.foregroundStyle] = newValue } }

        /// Use ``modify(frame:)`` to change the value.
        private(set) var frame: Frame? { get { self[.frame] } set { self[.frame] = newValue } }

        @usableFromInline
        var gridCellColumnSpan: Int? { get { self[.gridCellColumnSpan] } set { self[.gridCellColumnSpan] = newValue } }

        @usableFromInline
        var gridColumnAlignment: KvHorizontalAlignment? { get { self[.gridColumnAlignment] } set { self[.gridColumnAlignment] = newValue } }

        @usableFromInline
        var multilineTextAlignment: KvTextAlignment? { get { self[.multilineTextAlignment] } set { self[.multilineTextAlignment] = newValue } }

        @usableFromInline
        var navigationTitle: KvText? { get { self[.navigationTitle] } set { self[.navigationTitle] = newValue } }

        /// Use ``modify(padding:)`` or ``modify(paddingBlock:)`` to change the value.
        private(set) var padding: KvCssEdgeInsets? { get { self[.padding] } set { self[.padding] = newValue } }

        @usableFromInline
        var textCase: KvText.Case? { get { self[.textCase] } set { self[.textCase] = newValue } }


        // MARK: Operations

        /// This method redcuces number of explicit type declarations.
        private static func cast<T>(_ value: Any, as: KeyPath<Self, T?>) -> T { value as! T }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(background: KvAnyShapeStyle) -> Self? {
            guard !constraints.contains(.immutableBackground) else { return .init { $0.background = background } }

            self.background = background
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(clipShape: KvClipShape) -> Self? {
            // Clipshape can't be replaced.
            guard self.clipShape == nil else { return .init { $0.clipShape = clipShape } }

            self.clipShape = clipShape
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(frame: Frame) -> Self? {
            guard !constraints.contains(.immutableFrame),
                  self.frame == nil // Frame can't be replaced.
            else { return .init { $0.frame = frame } }

            self.frame = frame
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(padding: KvCssEdgeInsets) -> Self? {
            guard !constraints.contains(.immutablePadding) else { return .init { $0.padding = padding } }

            self.padding = self.padding + padding
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(paddingBlock: (KvCssEdgeInsets?) -> KvCssEdgeInsets?) -> Self? {
            guard !constraints.contains(.immutablePadding) else { return .init { $0.padding = paddingBlock(nil) } }

            self.padding = paddingBlock(self.padding)
            return nil
        }


        private mutating func resetConstraints() {
            var constraints: Constraints = .init()

            if clipShape != nil {
                constraints.formUnion([ .immutablePadding, .immutableFrame, .immutableBackground ])
            }
            if background != nil {
                constraints.formUnion([ .immutablePadding, .immutableFrame ])
            }
            if frame != nil {
                constraints.formUnion(.immutablePadding)
            }

            self.constraints = constraints
        }


        func navigationDestination(for data: String) -> NavigationDestinations.Destination? {
            navigationDestinations?.destination(for: data)
        }


        mutating func appendNavigationDestinations<C : KvView>(_ destinationProvider: @escaping (String) -> (view: C, value: Any)?) {
            let destinationProvider: NavigationDestinations.Provider = { data in
                destinationProvider(data).map { (body: KvHtmlBodyImpl(content: $0.view), value: $0.value) }
            }

            navigationDestinations?.append(provider: destinationProvider)
            ?? (navigationDestinations = .init(providers: [ destinationProvider ]))
        }


        // MARK: CSS

        /// - Returns: CSS attributes synthesized from the receiver.
        func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes? {
            guard !regularValues.isEmpty || !constrainedValues.isEmpty else { return nil }

            var css = KvHtmlKit.CssAttributes()

            regularValues.forEach { (key, value) in
                switch key {
                case .fixedSize:
                    css.append(style: Self.cast(value, as: \.fixedSize).cssFlexShrink(in: context))
                case .font:
                    css.append(style: Self.cast(value, as: \.font).cssStyle(in: context.html))
                case .foregroundStyle:
                    css.append(style: Self.cast(value, as: \.foregroundStyle).cssForegroundStyle(context.html, nil))
                case .gridCellColumnSpan:
                    css.append(style: "grid-column:span \(Self.cast(value, as: \.gridCellColumnSpan))")
                case .gridColumnAlignment:
                    css.insert(classes: context.html.cssFlexClass(for: Self.cast(value, as: \.gridColumnAlignment), as: .mainSelf))
                case .multilineTextAlignment:
                    css.append(style: "text-align:\(Self.cast(value, as: \.multilineTextAlignment).cssTextAlign.css)")
                case .textCase:
                    css.append(style: "text-transform:\(Self.cast(value, as: \.textCase).cssTextTransform)")

                case .navigationTitle:
                    break
                }
            }

            constrainedValues.forEach { (key, value) in
                switch key {
                case .background:
                    css.append(style: Self.cast(value, as: \.background).cssBackgroundStyle(context.html, nil))
                case .clipShape:
                    css.formUnion(Self.cast(value, as: \.clipShape).css)
                case .frame:
                    css.formUnion(Self.cast(value, as: \.frame).cssAttributes(in: context))
                case .padding:
                    css.append(style: "padding:\(Self.cast(value, as: \.padding).css)")
                }
            }

            return !css.isEmpty ? css : nil
        }


        // MARK: .FixedSize

        @usableFromInline
        struct FixedSize : OptionSet {

            @usableFromInline
            static let horizontal = Self(rawValue: 1 << 0)

            @usableFromInline
            static let vertical = Self(rawValue: 1 << 1)


            // MARK: Fabrics

            static func union(_ lhs: Self?, _ rhs: Self?) -> Self? {
                guard let lhs else { return rhs }
                guard let rhs else { return lhs }
                return lhs.union(rhs)
            }


            // MARK: : OptionSet

            @usableFromInline let rawValue: UInt

            @usableFromInline init(rawValue: UInt) { self.rawValue = rawValue }


            // MARK: Operations

            func cssFlexShrink(in context: borrowing KvHtmlRepresentationContext) -> String? {
                guard (contains(.horizontal) && context.containerAttributes?.layoutDirection == .horizontal)
                        || (contains(.vertical) && context.containerAttributes?.layoutDirection == .vertical)
                else { return nil }

                return "flex-shrink:0"
            }

        }


        // MARK: .Frame

        @usableFromInline
        struct Frame {

            @usableFromInline
            var width: Size?
            @usableFromInline
            var height: Size?
            @usableFromInline
            var alignment: KvAlignment


            @usableFromInline
            init(width: Size?, height: Size?, alignment: Alignment) {
                self.width = width
                self.height = height
                self.alignment = alignment
            }


            // MARK: .Size

            @usableFromInline
            struct Size {

                let minimum, ideal, maximum: KvCssLength?


                @usableFromInline
                init?(minimum: KvCssLength? = nil, ideal: KvCssLength? = nil, maximum: KvCssLength? = nil) {
                    guard minimum != nil || ideal != nil || maximum != nil else { return nil }

                    self.minimum = minimum
                    self.ideal = ideal
                    self.maximum = maximum
                }


                // MARK: Operations

                func cssAttributes(_ dimension: String, isMainAxis: Bool? = nil) -> KvHtmlKit.CssAttributes {
                    .init(
                        styles: ideal.map { "\(dimension):\($0.css)" },
                        minimum.map { "min-\(dimension):\($0.css)" },
                        maximum.flatMap {
                            switch ($0, isMainAxis) {
                            case (.value(.infinity, _), .some(let isMainAxis)):
                                isMainAxis ? "justify-self:stretch" : "align-self:stretch"
                            case (.value(.infinity, _), .none):
                                nil
                            default:
                                "max-\(dimension):\($0.css)"
                            }
                        }
                    )
                }

            }


            // MARK: Operations

            func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes {
                var attributes: KvHtmlKit.CssAttributes = .init(
                    classes: "flexH",
                    context.html.cssFlexClass(for: alignment.horizontal, as: .mainContent),
                    context.html.cssFlexClass(for: alignment.vertical, as: .crossItems)
                )

                let layoutDirection = context.containerAttributes?.layoutDirection

                if let widthCSS = width?.cssAttributes("width", isMainAxis: layoutDirection.map { $0 == .horizontal }) {
                    attributes.formUnion(widthCSS)
                }
                if let heightCSS = height?.cssAttributes("height", isMainAxis: layoutDirection.map { $0 == .vertical }) {
                    attributes.formUnion(heightCSS)
                }

                return attributes
            }

        }


        // MARK: .NavigationDestinations

        struct NavigationDestinations {

            typealias Destination = (body: KvHtmlBody, value: Any)
            typealias Provider = (String) -> Destination?


            init(providers: [Provider]) {
                self.providers = providers
            }


            private var providers: [Provider] = .init()


            // MARK: Fabrics

            static func merged(_ sources: Self?...) -> Self? {
                let providers = Array(sources
                    .lazy.compactMap { $0?.providers }
                    .joined())

                guard !providers.isEmpty else { return nil }

                return .init(providers: providers)
            }


            // MARK: Operations

            /// - Returns: The body and value the body has been synthesized for.
            func destination(for data: String) -> Destination? {
                providers
                    .lazy.compactMap { $0(data) }
                    .first
            }


            mutating func append(provider: @escaping Provider) {
                providers.append(provider)
            }

        }

    }

}
