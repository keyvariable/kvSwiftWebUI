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

    private(set) var bytes: KvHtmlBytes

    /// First declared title.
    var title: KvHtmlBytes?


    init(bytes: KvHtmlBytes, title: KvHtmlBytes? = nil) {
        self.bytes = bytes
        self.title = title
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
        return .init(bytes: .joined(i1.bytes, i2.bytes), title: i1.title ?? i2.title)
    }
    

    static func joined(_ i1: consuming Self,
                       _ i2: consuming Self,
                       _ i3: consuming Self
    ) -> Self {
        let i1 = i1, i2 = i2, i3 = i3

        let bytes: KvHtmlBytes = .joined(i1.bytes, i2.bytes, i3.bytes)
        let title: KvHtmlBytes? = i1.title ?? i2.title ?? i3.title

        return .init(bytes: bytes, title: title)
    }
    
    
    static func joined(_ i1: consuming Self,
                       _ i2: consuming Self,
                       _ i3: consuming Self,
                       _ i4: consuming Self
    ) -> Self {
        let i1 = i1, i2 = i2, i3 = i3, i4 = i4

        let bytes: KvHtmlBytes = .joined(i1.bytes, i2.bytes, i3.bytes, i4.bytes)
        let title: KvHtmlBytes? = i1.title ?? i2.title ?? i3.title ?? i4.title

        return .init(bytes: bytes, title: title)
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
struct KvHtmlRepresentationContext {

    let html: KvHtmlContext

    private(set) var environment: KvEnvironmentValues

    /// Context of current container.
    private(set) var containerAttributes: ContainerAttributes?

    private(set) var viewConfiguration: KvViewConfiguration?



    private init(html: KvHtmlContext,
                 environment: KvEnvironmentValues,
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


    init(html: KvHtmlContext, viewConfiguration: KvViewConfiguration? = nil) {
        self.init(html: html,
                  environment: viewConfiguration?.environment ?? .init(),
                  containerAttributes: nil,
                  viewConfiguration: viewConfiguration,
                  cssAttributes: nil)
    }



    /// Attributes to apply to the synthesized representation.
    private var cssAttributes: KvHtmlKit.CssAttributes?



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
        environment: KvEnvironmentValues? = nil,
        containerAttributes: ContainerAttributes? = nil,
        cssAttributes: KvHtmlKit.CssAttributes? = nil,
        options: Options = [ ],
        _ body: (borrowing KvHtmlRepresentationContext, borrowing KvHtmlKit.CssAttributes?, borrowing KvViewConfiguration?) -> KvHtmlRepresentation
    ) -> KvHtmlRepresentation {
        // Here self.container is passed to apply it in the droped CSS.
        var context = self.descendant(containerAttributes: self.containerAttributes)

        // TODO: Pass frame CSS to descendant context in come cases.
        let needsContainer = !options.contains(.noContainer) && viewConfiguration?.container?.frame != nil
        let containerCSS: KvHtmlKit.CssAttributes?

        switch consume needsContainer {
        case true:
            containerCSS = context.dropCssAttributes()

            context = context.descendant(environment: environment)

        case false:
            containerCSS = nil

            if let environment {
                context.formUnion(environment: environment)
            }
        }

        var representation : KvHtmlRepresentation
        do {
            let innerCSS = context.dropCssAttributes(mergedWith: cssAttributes)

            context.containerAttributes = containerAttributes

            // - NOTE: `self.viewConfiguration` is important.
            representation = body(context, innerCSS, self.viewConfiguration)
        }

        if let containerCSS {
            representation = representation.mapBytes {
                .tag(.div, css: containerCSS, innerHTML: $0)
            }
        }

        return representation
    }



    /// - Parameter environment: If provided then it's parent is set to the receiver's environment.
    /// - Parameter container: Context of container the resulting context is inside.
    /// - Parameter cssAttributes: Attributes to merge with the receiver's attributes.
    ///
    /// - Returns: New context with given values and optionally inherited values.
    func descendant(environment: KvEnvironmentValues? = nil,
                    containerAttributes: ContainerAttributes? = nil,
                    cssAttributes: KvHtmlKit.CssAttributes? = nil
    ) -> Self {
        var descendant = KvHtmlRepresentationContext(html: html,
                                                     environment: self.environment,
                                                     containerAttributes: containerAttributes,
                                                     viewConfiguration: self.viewConfiguration,
                                                     cssAttributes: self.cssAttributes)

        if let environment = environment {
            descendant.formUnion(environment: environment)
        }
        if let cssAttributes = cssAttributes {
            descendant.formUnion(cssAttributes: cssAttributes)
        }

        return descendant
    }


    /// Prodcuces descendant context where CSS attribute contets are merged or replaced with with given *viewConfiguration* whether possible.
    /// If it impossible to merge then replaced CSS atributes are writted into *droppedCssAttributes*.
    ///
    /// - Returns: The resulting context.
    func descendant(viewConfiguration: KvViewConfiguration,
                    droppedCssAttributes: inout KvHtmlKit.CssAttributes?
    ) -> KvHtmlRepresentationContext {
        var descendant: KvHtmlRepresentationContext

        switch KvViewConfiguration.merged(viewConfiguration, over: self.viewConfiguration) {
        case .merged(let mergeResult):
            // Container is passed to descendant in this case.
            descendant = self.descendant(environment: viewConfiguration.environment,
                                         containerAttributes: self.containerAttributes)
            descendant.viewConfiguration = mergeResult

        case .incompatibility:
            descendant = self
            droppedCssAttributes = descendant.dropCssAttributes()

            if let environment = viewConfiguration.environment {
                descendant.formUnion(environment: environment)
            }

            descendant.viewConfiguration = viewConfiguration
            descendant.containerAttributes = nil
        }

        return descendant
    }


    /// Produces descendant context for grid rows.
    func gridRowDescendant(_ verticalAlignment: KvVerticalAlignment?) -> KvHtmlRepresentationContext {
        containerAttributes?.gridNeedsSpanNextRow = false

        // Container context is passed to reset it later.
        var context = self.descendant(containerAttributes: containerAttributes)

        // Container context is changed here.
        if let gridAttributes = context.gridCssAttributes(verticalAlignment) {
            context.formUnion(cssAttributes: gridAttributes)
        }

        return context
    }



    /// - Returns: Extracted the receiver's CSS attributes optionaly merged with given *attributes*.
    ///
    /// - Note: The receiver's contents related to CSS attributes are reset. So the method's name starts with "drop" as similar methods in stadard collections.
    mutating func dropCssAttributes(mergedWith attributes: consuming KvHtmlKit.CssAttributes? = nil) -> KvHtmlKit.CssAttributes? {
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


    private mutating func gridCssAttributes(_ verticalAlignment: KvVerticalAlignment? = nil) -> KvHtmlKit.CssAttributes? {
        guard let container = containerAttributes else { return nil }

        container.gridColumnCounder?.increase(viewConfiguration?.gridCell?.gridCellColumnSpan ?? 1)

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


    mutating func formUnion(environment: KvEnvironmentValues) {
        guard environment !== self.environment else { return }

        environment.parent = self.environment
        self.environment = environment
    }


    /// Merges given *cssAttributes* into the receiver's CSS attributes.
    mutating func formUnion(cssAttributes: consuming KvHtmlKit.CssAttributes) {
        self.cssAttributes?.formUnion(cssAttributes)
        ?? (self.cssAttributes = cssAttributes)
    }

}
