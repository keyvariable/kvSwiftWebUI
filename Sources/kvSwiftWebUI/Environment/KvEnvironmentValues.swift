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

    var parent: Node?

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

    /// Getter returns the closest value in the hierarchy by given *key*.
    /// ``KvEnvironmentKey/defaultValue`` is returned if there is no value for *key*.
    public subscript<Key : KvEnvironmentKey>(key: Key.Type) -> Key.Value {
        get { value(forKey: key) ?? key.defaultValue }
        set { container[ObjectIdentifier(key)] = newValue }
    }


    func value<Key : KvEnvironmentKey>(forKey key: Key.Type) -> Key.Value? {
        firstResult { $0.container[ObjectIdentifier(key)] }
            .map { $0 as! Key.Value }
    }


    subscript<T>(viewConfiguration keyPath: KeyPath<ViewConfiguration, T?>) -> T? {
        firstResult {
            $0.viewConfiguration?[keyPath: keyPath]
        }
    }


    private func firstResult<T>(of block: (borrowing KvEnvironmentValues) -> T?) -> T? {
        if let value = block(self) {
            return value
        }

        do {
            var container = self

            while let next = container.parent?.values {
                if let value = block(next) {
                    return value
                }

                container = next
            }
        }

        return nil
    }



    // MARK: .Node

    /// Copy-by-reference container for ``KvEnvironmentValues``.
    class Node {

        let values: KvEnvironmentValues



        init(_ values: KvEnvironmentValues) {
            self.values = values
        }


        init(_ values: KvEnvironmentValues, parent: Node?) {
            var values = values
            values.parent = parent
            self.values = values
        }

    }

}



// MARK: View Configuration

extension KvEnvironmentValues {

    public var font: KvFont? { self[viewConfiguration: \.font] }

    public var foregroundStyle: KvAnyShapeStyle? { self[viewConfiguration: \.foregroundStyle] }

    public var multilineTextAlignment: KvTextAlignment? { self[viewConfiguration: \.multilineTextAlignment] }

    public var textCase: KvText.Case? { self[viewConfiguration: \.textCase] }



    // MARK: .ViewConfiguration

    @usableFromInline
    struct ViewConfiguration {

        private(set) var navigationDestinations: NavigationDestinations?
        

        init() { }


        init(_ transform: (inout ViewConfiguration) -> Void) {
            transform(&self)

            // - NOTE: It's possible to change constrained properties via private code.
            resetConstraints()
        }


        private var regularValues: [RegularKey : Any] = [:]
        private var constrainedValues: [ConstrainedKey : Any] = [:]

        private var constraints: Constraints = [ ]


        // MARK: .RegularKey

        /// Keys for properties having no constraints with other properties.
        enum RegularKey : Hashable, Comparable {
            case fixedSize
            case font
            case foregroundStyle
            case gridCellColumnSpan
            case gridColumnAlignment
            case multilineTextAlignment
            case navigationTitle
            case scriptResources
            case tag
            case textCase
        }


        // MARK: .ConstrainedKey

        /// Keys for properties having constraints with other properties. E.g. background can't be changed when padding is set.
        enum ConstrainedKey : Hashable, Comparable {
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

            let rawValue: UInt8

        }


        // MARK: Fabrics

        static func merged(_ addition: ViewConfiguration?, over base: ViewConfiguration?) -> KvMergeResult<ViewConfiguration?> {
            guard var addition else { return .merged(base) }
            guard let base else { return .merged(addition) }

            // Constrained values.
            // - IMPORTANT: Order of modifications matters. Modifications are applied as `base` is merged over `addition`.
            guard base.padding == nil || addition.modify(padding: base.padding!) == nil,
                  base.frame == nil || addition.modify(frame: base.frame!) == nil,
                  base.background == nil || addition.modify(background: base.background!) == nil,
                  base.clipShape == nil || addition.modify(clipShape: base.clipShape!) == nil
            else { return .incompatibility }

            var result = base

            result.constrainedValues = addition.constrainedValues
            result.constraints = addition.constraints

            // Regular values.
            addition.regularValues.forEach { (key, value) in
                switch key {
                case .fixedSize:
                    // Accumulation
                    result.fixedSize = .union(result.fixedSize, Self.cast(value, as: \.fixedSize))
                case .scriptResources:
                    // Accumulation
                    result.scriptResources = .union(result.scriptResources, Self.cast(value, as: \.scriptResources))
                case .font, .foregroundStyle, .gridCellColumnSpan, .gridColumnAlignment, .multilineTextAlignment, .navigationTitle,
                        .tag, .textCase:
                    // Replacement
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
        var scriptResources: KvAccumulatingOrderedSet<KvScriptResource>? { get { self[.scriptResources] } set { self[.scriptResources] = newValue } }

        @usableFromInline
        var tag: AnyHashable? { get { self[.tag] } set { self[.tag] = newValue } }

        @usableFromInline
        var textCase: KvText.Case? { get { self[.textCase] } set { self[.textCase] = newValue } }


        // MARK: Operations

        /// This method reduces number of explicit type declarations.
        private static func cast<T>(_ value: Any, as: KeyPath<ViewConfiguration, T?>) -> T { value as! T }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(background: KvAnyShapeStyle) -> ViewConfiguration? {
            guard !constraints.contains(.immutableBackground) else { return .init { $0.background = background } }

            self.background = background
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(clipShape: KvClipShape) -> ViewConfiguration? {
            // Clip shape can't be replaced.
            guard self.clipShape == nil else { return .init { $0.clipShape = clipShape } }

            self.clipShape = clipShape
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(frame: Frame) -> ViewConfiguration? {
            guard !constraints.contains(.immutableFrame),
                  self.frame == nil // Frame can't be replaced.
            else { return .init { $0.frame = frame } }

            self.frame = frame
            resetConstraints()
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(padding: KvCssEdgeInsets) -> ViewConfiguration? {
            guard !constraints.contains(.immutablePadding) else { return .init { $0.padding = padding } }

            self.padding = self.padding + padding
            return nil
        }


        /// - Returns: `nil` if modification has been applied or an instance with rejected values.
        @usableFromInline
        mutating func modify(paddingBlock: (KvCssEdgeInsets?) -> KvCssEdgeInsets?) -> ViewConfiguration? {
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


        mutating func appendNavigationDestinations<S, V>(staticData: S, destinationProvider: @escaping (String) -> (view: V, value: Any)?)
        where S : Sequence, S.Element == String, V : KvView
        {
            let destinationProvider: NavigationDestinations.Provider = { data in
                destinationProvider(data).map { (body: KvHtmlBodyImpl(content: $0.view), value: $0.value) }
            }

            if navigationDestinations == nil { navigationDestinations = .init() }

            navigationDestinations!.append(provider: destinationProvider)
            navigationDestinations!.insertStaticData(staticData)
        }


        // MARK: HTML

        /// - Returns: HTML tag attributes synthesized from the receiver.
        func htmlAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.Attributes? {
            guard !regularValues.isEmpty || !constrainedValues.isEmpty else { return nil }

            let attributes = KvHtmlKit.Attributes { attributes in
                regularValues.keys
                    .sorted()
                    .forEach { key in
                        let value = regularValues[key]!

                        switch key {
                        case .fixedSize:
                            attributes.append(optionalStyles: Self.cast(value, as: \.fixedSize).cssFlexShrink(in: context))

                        case .font:
                            attributes.append(styles: Self.cast(value, as: \.font).cssStyle(in: context))

                        case .foregroundStyle:
                            attributes.append(styles: Self.cast(value, as: \.foregroundStyle).cssForegroundStyle(context.html, nil))

                        case .gridCellColumnSpan:
                            let span = Self.cast(value, as: \.gridCellColumnSpan)
                            guard span > 1 else { break }
                            
                            attributes.append(styles: "grid-column:span \(span)")

                        case .gridColumnAlignment:
                            attributes.insert(classes: context.html.cssFlexClass(for: Self.cast(value, as: \.gridColumnAlignment), as: .mainSelf))

                        case .multilineTextAlignment:
                            attributes.append(styles: "text-align:\(Self.cast(value, as: \.multilineTextAlignment).cssTextAlign.css)")

                        case .tag:
                            let id: String? = switch value {
                            case let string as String: string
                            case let value as LosslessStringConvertible: value.description
                            case let value as any RawRepresentable:
                                switch value.rawValue {
                                case let string as String: string
                                case let value as LosslessStringConvertible: value.description
                                default: nil
                                }
                            default: nil
                            }
                            attributes[.id] = id.map { .string($0) }

                        case .textCase:
                            attributes.append(styles: "text-transform:\(Self.cast(value, as: \.textCase).cssTextTransform)")

                        case .navigationTitle, .scriptResources:
                            break
                        }
                    }

                constrainedValues.keys
                    .sorted()
                    .forEach { key in
                        let value = constrainedValues[key]!

                        switch key {
                        case .background:
                            attributes.append(styles: Self.cast(value, as: \.background).cssBackgroundStyle(context.html, nil))
                        case .clipShape:
                            attributes.formUnion(Self.cast(value, as: \.clipShape).htmlAttributes)
                        case .frame:
                            attributes.formUnion(Self.cast(value, as: \.frame).htmlAttributes(in: context))
                        case .padding:
                            attributes.append(styles: "padding:\(Self.cast(value, as: \.padding).css)")
                        }
                    }
            }

            return !attributes.isEmpty ? attributes : nil
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

            @usableFromInline let rawValue: UInt8

            @usableFromInline init(rawValue: UInt8) { self.rawValue = rawValue }


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


                // MARK: HTML

                func htmlAttributes(_ dimension: String, isMainAxis: Bool? = nil) -> KvHtmlKit.Attributes {
                    .init {
                        let ideal = ideal.map { "\(dimension):\($0.css)" }
                        let minimum = minimum.map { "min-\(dimension):\($0.css)" }
                        let maximum = maximum.flatMap {
                            switch ($0, isMainAxis) {
                            case (.value(.infinity, _), .some(let isMainAxis)):
                                isMainAxis ? "justify-self:stretch" : "align-self:stretch"
                            case (.value(.infinity, _), .none):
                                nil
                            default:
                                "max-\(dimension):\($0.css)"
                            }
                        }

                        $0.append(optionalStyles: ideal, minimum, maximum)
                    }
                }

            }


            // MARK: HTML

            func htmlAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.Attributes {
                .init { attributes in
                    attributes.insert(classes: "flexH",
                                      context.html.cssFlexClass(for: alignment.horizontal, as: .mainContent),
                                      context.html.cssFlexClass(for: alignment.vertical, as: .crossItems))

                    let layoutDirection = context.containerAttributes?.layoutDirection

                    if let widthAttributes = width?.htmlAttributes("width", isMainAxis: layoutDirection.map { $0 == .horizontal }) {
                        attributes.formUnion(widthAttributes)
                    }
                    if let heightAttributes = height?.htmlAttributes("height", isMainAxis: layoutDirection.map { $0 == .vertical }) {
                        attributes.formUnion(heightAttributes)
                    }
                }
            }

        }


        // MARK: .NavigationDestinations

        struct NavigationDestinations {

            typealias Destination = (body: KvHtmlBody, value: Any)
            typealias Provider = (String) -> Destination?


            init() { }


            private var providers: [Provider] = .init()

            /// Data values of known to be available destinations. These destinations are to be cached.
            private var staticData: Set<String> = .init()


            // MARK: Fabrics

            static func merged(_ sources: Self?...) -> Self? {
                let result = sources
                    .lazy.compactMap { $0 }
                    .reduce(into: NavigationDestinations()) { destinations, source in
                        destinations.providers.append(contentsOf: source.providers)
                        destinations.staticData.formUnion(source.staticData)
                    }

                guard !result.isEmpty else { return nil }

                return result
            }


            // MARK: Operations

            var isEmpty: Bool { providers.isEmpty }


            /// - Returns: The body and value the body has been synthesized for.
            func destination(for data: String) -> Destination? {
                providers
                    .lazy.compactMap { $0(data) }
                    .first
            }


            /// - Returns: Static data values and the resulting destinations grouped by the provider.
            func staticDestinations() -> AnySequence<[(data: String, destination: Destination)]> { .init(
                staticData
                    .reduce(into: [Int : [(data: String, destination: Destination)]]()) { accumulator, data in
                        guard let (offset, destination) = providers.enumerated()
                            .lazy.compactMap({ (offset, element) in element(data).map { (offset, $0) } })
                            .first
                        else { return }

                        accumulator[offset, default: .init()].append((data: data, destination: destination))
                    }
                    .values
            ) }


            mutating func append(provider: @escaping Provider) {
                providers.append(provider)
            }


            mutating func insertStaticData<S>(_ sequence: S) where S : Sequence, S.Element == String {
                staticData.formUnion(sequence)
            }

        }

    }

}
