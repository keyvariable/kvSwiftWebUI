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

import Foundation



struct KvHtmlRepresentation {

    static let empty = KvHtmlRepresentation()



    private init() {
        dataList = .init()
    }


    init<V : KvView>(of view: V, in context: KvHtmlRepresentationContext) {
        var dataList = DataList()

        var fragment = view.htmlRepresentation(in: context)

        while let payload = fragment.dropFirst() {
            switch payload {
            case .data(let data):
                dataList.append(.data(data))

            case .dataBlock(let dataBlock):
                dataList.append(.dataBlock(dataBlock))

            case .dataList(let list):
                dataList.append(.dataList(list))

            case .fragmentBlock(let fragmentBlock):
                var nextFragment = fragmentBlock()

                nextFragment.append(fragment)
                fragment = nextFragment
            }
        }

        self.dataList = dataList
    }



    private let dataList: DataList



    // MARK: Operations

    func forEach(_ body: (Data) -> Void) {
        dataList.forEach(body)
    }



    // MARK: .Fragment

    struct Fragment {

        private var first: Node?
        private var last: Node?


        init() { }


        init(_ payload: Payload) {
            first = .init(with: payload)
            last = first
        }


        init(_ string: String) { self.init(.string(string)) }


        init(fragmentBlock: @escaping () -> Fragment) { self.init(.fragmentBlock(fragmentBlock)) }


        init<S>(_ payload: S) where S : Sequence, S.Element == Payload {
            payload.forEach { append($0) }
        }


        init(_ payload: Payload...) { self.init(payload) }


        init<S>(_ payload: S) where S : Sequence, S.Element == Fragment {
            payload.forEach { append($0) }
        }


        init(_ payload: Fragment...) {
            payload.forEach { append($0) }
        }


        // MARK: Fabrics

        static let empty = Fragment()


        /// - Note: Assuming one of arguments are non-empty.
        private static func tag(opening: consuming Payload, innerHTML: consuming Fragment?, closing: consuming Payload?) -> Fragment {
            var fragment = Fragment(opening)
            if let innerHTML {
                fragment.append(innerHTML)
            }
            if let closing {
                fragment.append(closing)
            }
            return fragment
        }


        static func tag<Attributes>(_ tag: KvHtmlKit.Tag,
                                    css: KvHtmlKit.CssAttributes? = nil,
                                    attributes: Attributes,
                                    innerHTML: consuming Fragment? = nil
        ) -> Fragment
        where Attributes : Sequence, Attributes.Element == KvHtmlKit.Attribute
        {
            let hasContent = innerHTML != nil
            let opening = tag.opening(css: css, attributes: attributes, hasContent: hasContent)
            let closing = tag.closing(hasContent: hasContent)

            return self.tag(opening: .string(opening), innerHTML: innerHTML, closing: closing.map(Payload.string(_:)))
        }


        static func tag<Attributes>(_ tag: KvHtmlKit.Tag,
                                    css: @escaping () -> KvHtmlKit.CssAttributes? = { nil },
                                    attributes: @escaping () -> Attributes = { [ ] },
                                    innerHTML: consuming Fragment? = nil
        ) -> Fragment
        where Attributes : Sequence, Attributes.Element == KvHtmlKit.Attribute
        {
            let hasContent = innerHTML != nil
            let opening = Payload.stringBlock { tag.opening(css: css(), attributes: attributes(), hasContent: hasContent) }
            let closing = tag.closing(hasContent: hasContent)

            return self.tag(opening: opening, innerHTML: innerHTML, closing: closing.map(Payload.string(_:)))
        }


        static func tag(_ tag: KvHtmlKit.Tag,
                        css: KvHtmlKit.CssAttributes? = nil,
                        attributes: KvHtmlKit.Attribute?...,
                        innerHTML: consuming Fragment? = nil
        ) -> Self {
            self.tag(tag, css: css, attributes: attributes.lazy.compactMap { $0 }, innerHTML: innerHTML)
        }


        // MARK: .Payload

        enum Payload : ExpressibleByStringLiteral, ExpressibleByStringInterpolation {

            case data(Data)
            /// This case is used when the resulting data depends on fragments generated later.
            case dataBlock(() -> Data)
            case dataList(DataList)
            /// This case is used to avoid recursion while traversing view hierarchies.
            case fragmentBlock(() -> Fragment)


            // MARK: Fabrics

            static func dataList(_ representation: KvHtmlRepresentation) -> Payload { .dataList(representation.dataList) }


            static func string(_ value: String) -> Payload { .data(value.data(using: .utf8)!) }


            static func stringBlock(_ block: @escaping () -> String) -> Payload { .dataBlock { block().data(using: .utf8)! } }


            // MARK: : ExpressibleByStringLiteral

            init(stringLiteral value: StringLiteralType) { self = .data(value.data(using: .utf8)!) }

        }


        // MARK: .Node

        private class Node {

            let payload: Payload

            var next: Node?


            init(with payload: Payload) {
                self.payload = payload
            }

        }


        // MARK: Operations

        var hasPayload: Bool { last != nil }


        mutating func append(_ fragment: consuming Fragment) {
            if fragment.last != nil {
                switch last != nil {
                case true:
                    last!.next = fragment.first
                case false:
                    first = fragment.first
                }
                last = fragment.last
            }
        }


        mutating private func append(_ payload: Payload) {
            let node = Node(with: payload)

            switch last != nil {
            case true:
                last!.next = node
            case false:
                first = node
            }
            last = node
        }


        mutating func append(_ data: Data) { append(.data(data)) }


        mutating func dropFirst() -> Payload? {
            guard last != nil else { return nil }

            let payload = first!.payload

            switch first === last {
            case false:
                first = first?.next
                assert(first != nil)
            case true:
                first = nil
                last = nil
            }

            return payload
        }

    }



    // MARK: .DataList

    struct DataList {

        init() { }


        private var first, last: Node?


        // MARK: .Payload

        enum Payload {
            case data(Data)
            case dataBlock(() -> Data)
            case dataList(DataList)
        }


        // MARK: .Node

        fileprivate class Node {

            /// - Note: It's a variable to provide lazy replacement of data blocks with the resulting data.
            var payload: Payload
            var next: Node?


            init(with payload: Payload) {
                self.payload = payload
            }

        }


        // MARK: Operations

        func forEach(_ body: (Data) -> Void) {
            var next = first

            while let node = next {
                switch node.payload {
                case .data(let data):
                    body(data)

                case .dataBlock(let block):
                    let data = block()
                    // Once data block is invoked, it's replaced with the resulting data.
                    node.payload = .data(data)
                    body(data)

                case .dataList(let dataList):
                    dataList.forEach(body)
                }

                next = node.next
            }
        }


        mutating func append(_ payload: Payload) {
            let node = Node(with: payload)

            switch last != nil {
            case true:
                last!.next = node
            case false:
                first = node
            }
            last = node
        }

    }

}



// MARK: - KvHtmlRepresentationContext

// TODO: Review this class. Currently it's unintuitive and complicated, some methods produce side-effects.
class KvHtmlRepresentationContext {

    typealias EnvironmentNode = KvEnvironmentValues.Node



    let html: KvHtmlContext

    private(set) var environmentNode: EnvironmentNode?

    /// Context of current container.
    private(set) var containerAttributes: ContainerAttributes?



    private init(html: KvHtmlContext,
                 environmentNode: EnvironmentNode?,
                 containerAttributes: ContainerAttributes?,
                 viewConfiguration: KvViewConfiguration?,
                 cssAttributes: KvHtmlKit.CssAttributes?
    ) {
        self.html = html
        self.environmentNode = environmentNode
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
              environmentNode: environment.map(EnvironmentNode.init(_:)),
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

        /// It's counted in child contexts returned by ``nextGridRow``. Then maximum of the resulting values is used by the grid's context.
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

        /// Increases internal value when ``increase`` method is called and invokes the block with the result when deinitiated.
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
        _ body: (KvHtmlRepresentationContext, borrowing KvHtmlKit.CssAttributes?) -> KvHtmlRepresentation.Fragment
    ) -> KvHtmlRepresentation.Fragment {
        // Here `self.containerAttributes` is passed to apply it in the extracted CSS.
        var context = self.descendant(containerAttributes: self.containerAttributes)

        // TODO: Pass frame CSS to descendant context in come cases.
        let needsContainer = !options.contains(.noContainer) && viewConfiguration?.frame != nil
        let containerCSS: KvHtmlKit.CssAttributes?// = (consume needsContainer) ? context.extractCssAttributes() : nil

        switch consume needsContainer {
        case true:
            containerCSS = context.extractCssAttributes()

            context = context.descendant()

        case false:
            containerCSS = nil
        }

        var fragment : KvHtmlRepresentation.Fragment
        do {
            let innerCSS = context.extractCssAttributes(mergedWith: cssAttributes)

            context.containerAttributes = containerAttributes

            // - NOTE: `self.viewConfiguration` is important.
            fragment = body(context, innerCSS)
        }

        if let containerCSS {
            fragment = .tag(.div, css: containerCSS, innerHTML: fragment)
        }

        return fragment
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
                     environmentNode: environmentNode,
                     containerAttributes: containerAttributes,
                     viewConfiguration: self.viewConfiguration,
                     cssAttributes: cssAttributes)
    }


    /// If *environment* contains view configuration then
    /// method produces descendant context where view configuration is merged or replaced with given value.
    /// If it's impossible to merge then replaced view configuration is converted to CSS and the result is written into *extractedCssAttributes*.
    ///
    /// - Returns: The resulting context.
    func descendant(environment: KvEnvironmentValues,
                    extractedCssAttributes: inout KvHtmlKit.CssAttributes?
    ) -> KvHtmlRepresentationContext {
        let descendant: KvHtmlRepresentationContext

        let environmentNode = EnvironmentNode(environment, parent: environmentNode)


        func Descendant(_ viewConfiguration: KvViewConfiguration? = nil) -> KvHtmlRepresentationContext {
            // Container is passed to descendant in this case.
            .init(html: html,
                  environmentNode: environmentNode,
                  containerAttributes: self.containerAttributes,
                  viewConfiguration: viewConfiguration ?? self.viewConfiguration,
                  cssAttributes: self.cssAttributes)
        }


        switch KvViewConfiguration.merged(environmentNode.values.viewConfiguration, over: self.viewConfiguration) {
        case .merged(let mergeResult):
            descendant = Descendant(mergeResult)

        case .incompatibility:
            // The receiver is cloned to extract CSS then.
            descendant = Descendant()

            extractedCssAttributes = descendant.extractCssAttributes()

            descendant.viewConfiguration = environmentNode.values.viewConfiguration
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



    /// - Returns: Extracted the receiver's CSS attributes optionally merged with given *attributes*.
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
        environmentNode = .init(environment, parent: environmentNode)
    }


    /// Merges given *cssAttributes* into the receiver's CSS attributes.
    private func push(cssAttributes: consuming KvHtmlKit.CssAttributes) {
        self.cssAttributes?.formUnion(cssAttributes)
        ?? (self.cssAttributes = cssAttributes)
    }

}
