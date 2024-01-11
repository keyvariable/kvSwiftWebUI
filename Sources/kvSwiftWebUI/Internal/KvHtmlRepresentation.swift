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
//  KvHtmlRepresentation.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 26.10.2023.
//

struct KvHtmlRepresentation {

    typealias NavigationDestinations = KvViewConfiguration.NavigationDestinations



    private(set) var bytes: KvHtmlBytes

    /// First declared title.
    var title: KvHtmlBytes?

    /// All declared destinations.
    var navigationDestinations: NavigationDestinations?


    init(bytes: KvHtmlBytes, title: KvHtmlBytes? = nil, navigationDestinations: NavigationDestinations? = nil) {
        self.bytes = bytes
        self.title = title
        self.navigationDestinations = navigationDestinations
    }



    // MARK: Fabrics

    static let empty = Self(bytes: .empty)



    // MARK: Merging

    static func joined<S>(_ elements: S) -> Self
    where S : Sequence, S.Element == Self {
        var representation = KvHtmlRepresentation.empty

        var iterator = elements.makeIterator()

        while let r0 = iterator.next() {
            guard let r1 = iterator.next() else {
                representation = .joined(representation, r0)
                break
            }
            guard let r2 = iterator.next() else {
                representation = .joined(representation, r0, r1)
                break
            }
            representation = .joined(representation, r0, r1, r2)
        }

        return representation
    }



    static func joined(_ i1: consuming Self,
                       _ i2: consuming Self
    ) -> Self {
        let i1 = i1, i2 = i2
        return .init(bytes: .joined(i1.bytes, i2.bytes),
                     title: i1.title ?? i2.title,
                     navigationDestinations: .merged(i1.navigationDestinations, i2.navigationDestinations)
        )
    }
    

    static func joined(_ i1: consuming Self,
                       _ i2: consuming Self,
                       _ i3: consuming Self
    ) -> Self {
        let i1 = i1, i2 = i2, i3 = i3

        let bytes: KvHtmlBytes = .joined(i1.bytes, i2.bytes, i3.bytes)
        let title: KvHtmlBytes? = i1.title ?? i2.title ?? i3.title
        let navigationDestinations: NavigationDestinations? = .merged(i1.navigationDestinations, i2.navigationDestinations, i3.navigationDestinations)

        return .init(bytes: bytes, title: title, navigationDestinations: navigationDestinations)
    }
    
    
    static func joined(_ i1: consuming Self,
                       _ i2: consuming Self,
                       _ i3: consuming Self,
                       _ i4: consuming Self
    ) -> Self {
        let i1 = i1, i2 = i2, i3 = i3, i4 = i4

        let bytes: KvHtmlBytes = .joined(i1.bytes, i2.bytes, i3.bytes, i4.bytes)
        let title: KvHtmlBytes? = i1.title ?? i2.title ?? i3.title ?? i4.title
        let navigationDestinations: NavigationDestinations? = .merged(i1.navigationDestinations, i2.navigationDestinations, i3.navigationDestinations, i4.navigationDestinations)

        return .init(bytes: bytes, title: title, navigationDestinations: navigationDestinations)
    }



    // MARK: Transformations

    consuming func mapBytes(_ transform: (KvHtmlBytes) -> KvHtmlBytes) -> Self {
        var copy = self
        copy.bytes = transform(copy.bytes)
        return copy
    }



    // MARK: Operators

    static func +(lhs: consuming Self, rhs: consuming Self) -> Self { .joined(lhs, rhs) }

}



// MARK: - KvHtmlRepresentationContext

// TODO: Review this class. Currently it's unintuitive and complicated, some methods produce side-effects.
class KvHtmlRepresentationContext {

    let html: KvHtmlContext

    private(set) var environment: KvEnvironmentNode?

    /// Context of current container.
    private(set) var containerAttributes: ContainerAttributes?



    private init(html: KvHtmlContext,
                 environment: KvEnvironmentNode?,
                 containerAttributes: ContainerAttributes?,
                 viewConfiguration: KvViewConfiguration?,
                 cssAttributes: KvHtmlKit.CssAttributes?
    ) {
        self.html = html
        self.environment = environment
        self.containerAttributes = containerAttributes
        self.viewConfiguration = viewConfiguration
        self.cssAttributes = cssAttributes
    }



    /// Merged view configuration environments.
    private var viewConfiguration: KvViewConfiguration?

    /// Attributes to apply to the synthesized representation.
    private var cssAttributes: KvHtmlKit.CssAttributes?



    // MARK: Fabrics

    static func root(html: KvHtmlContext, environment: KvEnvironmentValues? = nil) -> KvHtmlRepresentationContext {
        .init(html: html,
              environment: environment.map { .init(values: $0) },
              containerAttributes: nil,
              viewConfiguration: environment?.viewConfiguration,
              cssAttributes: nil)
    }



    // MARK: .ContainerAttributes

    final class ContainerAttributes {

        let layoutDirection: KvLayoutDirection?

        /// This flag is set to `true` each time ``nextGridRow`` is called. ``KvGridRow`` sets this flag to `false`.
        /// It's used to add grid span style instruction to custom views.
        fileprivate var gridNeedsSpanNextRow: Bool = true

        /// It's counted in child contexts retured by ``nextGridRow``. Then maximum of the resuling values is used by the grid's context.
        private(set) var gridColumnCount: Int?

        fileprivate let gridColumnCounder: RaiiCounter<Int>?



        private init(layoutDirection: KvLayoutDirection? = nil,
                     layoutAlignment: KvAlignment? = nil,
                     gridColumnCounder: RaiiCounter<Int>? = nil,
                     nextGridRow: Int? = nil
        ) {
            self.layoutDirection = layoutDirection
            self._layoutAlignment = layoutAlignment
            self.gridColumnCounder = gridColumnCounder
            self.gridNextRowIndex = nextGridRow
        }



        private let _layoutAlignment: KvAlignment?

        private var gridNextRowIndex: Int?



        // MARK: Fabrics

        static func grid(_ alignmnet: KvAlignment?) -> Self { .init(layoutDirection: .horizontal, layoutAlignment: alignmnet, nextGridRow: 1) }


        static func stack(_ direction: KvLayoutDirection) -> Self { .init(layoutDirection: direction) }



        // MARK: Operations

        fileprivate func nextGridRow(_ verticalAlignment: KvVerticalAlignment?) -> (containerAttributes: ContainerAttributes, index: Int, spanFlag: Bool)? {
            guard let value = gridNextRowIndex else { return nil }

            defer {
                gridNextRowIndex = value + 1
                gridNeedsSpanNextRow = true
            }

            let columnCounter = RaiiCounter(0) { [weak self] count in
                guard count >= 2,
                      let container = self,
                      container.gridColumnCount == nil || container.gridColumnCount! < count
                else { return }

                container.gridColumnCount = count
            }

            return (containerAttributes: .init(layoutDirection: layoutDirection, // Layout direction is passed to grid rows.
                                               layoutAlignment: layoutAlignment(vertical: verticalAlignment),
                                               gridColumnCounder: columnCounter),
                    index: value,
                    spanFlag: gridNeedsSpanNextRow)
        }


        /// - Returns: The receiver's layout alignment with replaced components if both the alignment component and replacement are non-nil.
        func layoutAlignment(horizontal: KvHorizontalAlignment? = nil, vertical: KvVerticalAlignment? = nil) -> KvAlignment? {
            guard var alignment = _layoutAlignment else { return nil }

            alignment.horizontal = horizontal ?? alignment.horizontal
            alignment.vertical = vertical ?? alignment.vertical

            return alignment
        }



        // MARK: .RaiiCounter

        /// Increases internal value when ``increase`` method is called and invokes the block with the result when deinitialized.
        class RaiiCounter<T : Numeric> {

            init(_ initialValue: T, completion: @escaping (T) -> Void) {
                self.value = initialValue
                self.completionBlock = completion
            }


            deinit { completionBlock(value) }


            private var value: T
            private let completionBlock: (T) -> Void


            // MARK: Operations

            func increase(_ increment: T = 1) { value += increment }

        }

    }



    // MARK: .Options

    struct Options : OptionSet {

        static let noContainer = Self(rawValue: 1 << 0)


        let rawValue: UInt8

    }



    // MARK: Operations

    func representation(
        containerAttributes: ContainerAttributes? = nil,
        cssAttributes: KvHtmlKit.CssAttributes? = nil,
        options: Options = [ ],
        _ body: (borrowing KvHtmlRepresentationContext, borrowing KvHtmlKit.CssAttributes?) -> KvHtmlRepresentation
    ) -> KvHtmlRepresentation {
        // Here `self.containerAttributes` is passed to apply it in the extracted CSS.
        let context = self.descendant(containerAttributes: self.containerAttributes)

        // TODO: Pass frame CSS to descendant context in come cases.
        let needsContainer = !options.contains(.noContainer) && viewConfiguration?.frame != nil
        let containerCSS = needsContainer ? context.extractCssAttributes() : nil

        var representation : KvHtmlRepresentation
        do {
            let innerCSS = context.extractCssAttributes(mergedWith: cssAttributes)

            context.containerAttributes = containerAttributes

            // - NOTE: `self.viewConfiguration` is important.
            representation = body(context, innerCSS)
        }

        if let containerCSS {
            representation = representation.mapBytes {
                .tag(.div, css: containerCSS, innerHTML: $0)
            }
        }

        return representation
    }



    /// - Parameter container: Context of container the resulting context is inside.
    /// - Parameter cssAttributes: Attributes to merge with the receiver's attributes.
    ///
    /// - Returns: New context with given values and optionally inherited values.
    func descendant(containerAttributes: ContainerAttributes? = nil,
                    cssAttributes: KvHtmlKit.CssAttributes? = nil
    ) -> KvHtmlRepresentationContext {
        let cssAttributes = KvHtmlKit.CssAttributes.union(self.cssAttributes, cssAttributes)

        return .init(html: html,
                     environment: environment,
                     containerAttributes: containerAttributes,
                     viewConfiguration: self.viewConfiguration,
                     cssAttributes: cssAttributes)
    }


    /// If *environment* contains view configuration then
    /// method prodcuces descendant context where view configuration is merged or replaced with given value.
    /// If it's impossible to merge then replaced view configuration is converted to CSS and the result is written into *extractedCssAttributes*.
    ///
    /// - Returns: The resulting context.
    func descendant(environment: KvEnvironmentValues,
                    extractedCssAttributes: inout KvHtmlKit.CssAttributes?
    ) -> KvHtmlRepresentationContext {
        let descendant: KvHtmlRepresentationContext

        let environment = KvEnvironmentNode(parent: self.environment, values: environment)


        func Descendant(_ viewConfiguration: KvViewConfiguration? = nil) -> KvHtmlRepresentationContext {
            // Container is passed to descendant in this case.
            .init(html: html,
                  environment: environment,
                  containerAttributes: self.containerAttributes,
                  viewConfiguration: viewConfiguration ?? self.viewConfiguration,
                  cssAttributes: self.cssAttributes)
        }


        switch KvViewConfiguration.merged(environment.values.viewConfiguration, over: self.viewConfiguration) {
        case .merged(let mergeResult):
            descendant = Descendant(mergeResult)

        case .incompatibility:
            // The receiver is cloned to extract CSS then.
            descendant = Descendant()

            extractedCssAttributes = descendant.extractCssAttributes()

            descendant.viewConfiguration = environment.values.viewConfiguration
            descendant.containerAttributes = nil
        }

        return descendant
    }


    /// Produces descendant context for grid rows.
    func gridRowDescendant(_ verticalAlignment: KvVerticalAlignment?) -> KvHtmlRepresentationContext {
        containerAttributes?.gridNeedsSpanNextRow = false

        // Container context is passed to reset it later.
        let context = self.descendant(containerAttributes: containerAttributes)

        // Container context is changed here.
        if let gridAttributes = context.gridCssAttributes(verticalAlignment) {
            context.push(cssAttributes: gridAttributes)
        }

        return context
    }



    /// - Returns: Extracted the receiver's CSS attributes optionaly merged with given *attributes*.
    ///
    /// - Note: The receiver's contents related to CSS attributes are reset.
    /// - Important: Extraction of CSS has some side effects.
    private func extractCssAttributes(mergedWith attributes: consuming KvHtmlKit.CssAttributes? = nil) -> KvHtmlKit.CssAttributes? {
        var cssAttributes = KvHtmlKit.CssAttributes.union(viewConfiguration?.cssAttributes(in: self), self.cssAttributes)


        func Accumulate(_ attributes: KvHtmlKit.CssAttributes) {
            cssAttributes?.formUnion(attributes) ?? (cssAttributes = attributes)
        }


        if let gridAttributes = gridCssAttributes() {
            Accumulate(gridAttributes)
        }
        if let attributes = attributes {
            Accumulate(attributes)
        }

        self.viewConfiguration = nil
        self.cssAttributes = nil

        return cssAttributes
    }


    private func gridCssAttributes(_ verticalAlignment: KvVerticalAlignment? = nil) -> KvHtmlKit.CssAttributes? {
        guard let container = containerAttributes else { return nil }

        container.gridColumnCounder?.increase(viewConfiguration?.gridCellColumnSpan ?? 1)

        guard let (rowContainerAttributes, rowIndex, spanFlag) = container.nextGridRow(verticalAlignment) else { return nil }

        self.containerAttributes = rowContainerAttributes

        var attributes = KvHtmlKit.CssAttributes(
            styles: "grid-row:\(rowIndex)",
            spanFlag ? "grid-column:1/-1" : nil
        )

        if let flexClass = verticalAlignment.map({ html.cssFlexClass(for: $0, as: .crossSelf) }) {
            attributes.insert(classes: flexClass)
        }

        return attributes
    }


    func push(environment: KvEnvironmentValues) {
        self.environment = .init(parent: self.environment, values: environment)
    }


    /// Merges given *cssAttributes* into the receiver's CSS attributes.
    private func push(cssAttributes: consuming KvHtmlKit.CssAttributes) {
        self.cssAttributes?.formUnion(cssAttributes)
        ?? (self.cssAttributes = cssAttributes)
    }

}
