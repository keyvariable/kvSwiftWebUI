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

import kvCssKit



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

        private(set) var attributes: Attributes


        init(attributes: Attributes = .empty) {
            self.attributes = attributes
        }


        init(_ payload: Payload, attributes: Attributes = .empty) {
            first = .init(with: payload)
            last = first
            self.attributes = attributes
        }


        init(_ string: String, attributes: Attributes = .empty) {
            self.init(.string(string), attributes: attributes)
        }


        init(attributes: Attributes = .empty, fragmentBlock: @escaping () -> Fragment) {
            self.init(.fragmentBlock(fragmentBlock), attributes: attributes)
        }


        init<S>(_ payload: S, attributes: Attributes = .empty)
        where S : Sequence, S.Element == Payload
        {
            self.attributes = attributes
            payload.forEach { append($0) }
        }


        init(_ payload: Payload..., attributes: Attributes = .empty) {
            self.init(payload, attributes: attributes)
        }


        init<S>(_ payload: S, attributes: Attributes = .empty)
        where S : Sequence, S.Element == Fragment
        {
            self.attributes = attributes
            payload.forEach { append($0) }
        }


        init(_ payload: Fragment..., attributes: Attributes = .empty) {
            self.attributes = attributes
            payload.forEach { append($0) }
        }


        // MARK: Fabrics

        static let empty = Fragment()


        /// - Note: Assuming one of arguments are non-empty.
        private static func tag(opening: consuming Payload,
                                innerHTML: consuming Fragment?,
                                closing: consuming Payload?,
                                attributes: Attributes
        ) -> Fragment {
            var fragment = Fragment(opening, attributes: attributes)
            if let innerHTML {
                fragment.append(innerHTML)
            }
            if let closing {
                fragment.append(closing)
            }
            return fragment
        }


        /// - Note: Given tag is added to ``attributes`` of the resulting fragment.
        static func tag(_ tag: KvHtmlKit.Tag, attributes: KvHtmlKit.Attributes, innerHTML: consuming Fragment? = nil) -> Fragment {
            let hasContent = innerHTML != nil
            let opening = tag.opening(attributes: attributes, hasContent: hasContent)
            let closing = tag.closing(hasContent: hasContent)

            return self.tag(
                opening: .string(opening),
                innerHTML: innerHTML,
                closing: closing.map(Payload.string(_:)),
                attributes: .init {
                    $0.htmlTag = tag
                }
            )
        }


        /// - Note: Given tag is added to ``attributes`` of the resulting fragment.
        static func tag(_ tag: KvHtmlKit.Tag,
                        attributes: @escaping () -> KvHtmlKit.Attributes = { .empty },
                        innerHTML: consuming Fragment? = nil
        ) -> Fragment {
            let hasContent = innerHTML != nil
            let opening = Payload.stringBlock { tag.opening(attributes: attributes(), hasContent: hasContent) }
            let closing = tag.closing(hasContent: hasContent)

            return self.tag(
                opening: opening,
                innerHTML: innerHTML,
                closing: closing.map(Payload.string(_:)),
                attributes: .init {
                    $0.htmlTag = tag
                }
            )
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


        // MARK: .Attributes

        struct Attributes {

            static let empty = Attributes()


            init() { }


            /// Initializes an instance and invokes given *transform* for the instance.
            init(_ transform: (inout Attributes) -> Void) {
                transform(&self)
            }


            private var values: [Attribute : Any] = .init()


            // MARK: .Attribute

            enum Attribute : Hashable {
                /// HTML tag the content is wrapped into.
                case htmlTag
            }


            // MARK: Access

            private subscript<T>(key: Attribute) -> T? {
                get { values[key] as! T? }
                set { values[key] = newValue }
            }


            var htmlTag: KvHtmlKit.Tag? { get { self[.htmlTag] } set { self[.htmlTag] = newValue } }

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
                 htmlAttributes: KvHtmlKit.Attributes?
    ) {
        self.html = html
        self.environmentNode = environmentNode
        self.containerAttributes = containerAttributes
        self.viewConfiguration = viewConfiguration
        self.htmlAttributes = htmlAttributes
    }



    /// Merged view configuration environments.
    private var viewConfiguration: KvViewConfiguration?

    /// Attributes to apply to the synthesized representation.
    private var htmlAttributes: KvHtmlKit.Attributes?



    // MARK: Fabrics

    static func root(html: KvHtmlContext, viewConfiguration: KvViewConfiguration? = nil) -> KvHtmlRepresentationContext {
        var environment: KvEnvironmentValues = .init(viewConfiguration)

        environment.defaultBundle = html.defaultBundle
        environment.navigationPath = html.navigationPath
        environment.localization = html.localizationContext

        return .init(html: html,
                     environmentNode: EnvironmentNode(environment),
                     containerAttributes: nil,
                     viewConfiguration: viewConfiguration,
                     htmlAttributes: nil)
    }



    // MARK: .ContainerAttributes

    final class ContainerAttributes {

        typealias WrappingBlock = (borrowing KvHtmlKit.Attributes, borrowing KvHtmlRepresentation.Fragment) -> KvHtmlRepresentation.Fragment



        let layout: Layout?
        let layoutDirection: KvLayoutDirection?

        /// This block is applied to each child view in a group.
        fileprivate let wrapperBlock: WrappingBlock?



        private init(layout: Layout? = nil, layoutDirection: KvLayoutDirection? = nil, wrapperBlock: WrappingBlock? = nil) {
            self.layout = layout
            self.layoutDirection = layoutDirection
            self.wrapperBlock = wrapperBlock
        }



        // MARK: Fabrics

        static func grid() -> ContainerAttributes { .init(layout: .grid(.init()), layoutDirection: .horizontal) }


        /// A list that is rendered as `<ol>` and `<ul>` HTML tags.
        static var htmlList: ContainerAttributes {
            .init(layoutDirection: .vertical, wrapperBlock: { htmlAttributes, innerFragment in
                let containerTag: KvHtmlKit.Tag? = switch innerFragment.attributes.htmlTag {
                case .ul, .ol:
                    /// These tags should not be wrapped into `<li>` container.
                    !htmlAttributes.isEmpty ? .div : nil
                default:
                    .li
                }

                guard let containerTag else { return innerFragment }

                return .tag(containerTag, attributes: htmlAttributes, innerHTML: innerFragment)
            })
        }


        static func stack(_ direction: KvLayoutDirection) -> ContainerAttributes { .init(layoutDirection: direction) }



        // MARK: Operations

        /// - Returns: The attributes and the row.
        fileprivate func nextGridRow() -> (container: ContainerAttributes, row: Grid.Row)? {
            guard case .grid(let grid) = layout else {
                assertionFailure("Internal inconsistency: «\(String(describing: layout))» layout is not `.grid(_)`")
                return nil
            }

            let row = grid.nextRow()
            let container = ContainerAttributes(
                layout: .gridRow(row),
                layoutDirection: layoutDirection    // Layout direction is passed to grid rows.
            )

            return (container: container, row: row)
        }



        // MARK: .Layout

        enum Layout {

            case grid(Grid)
            case gridRow(Grid.Row)


            // MARK: Shorthands

            var grid: Grid? {
                guard case .grid(let grid) = self else { return nil }
                return grid
            }

            var gridRow: Grid.Row? {
                guard case .gridRow(let row) = self else { return nil }
                return row
            }


            // MARK: Operations

            var isGrid: Bool {
                switch self {
                case .grid(_), .gridRow(_):
                    true
                }
            }
        }



        // MARK: .Grid

        class Grid {

            /// It's updated in child contexts returned by ``nextGridRow``.
            private(set) var columnWidths: [ColumnWidth] = .init()


            private var nextRowIndex: Int = 0


            // MARK: .ColumnWidth

            enum ColumnWidth {

                case auto
                case fixed(KvCssLength)
                /// A placeholder value. E.g. it's used when a spanned cell is inserted.
                case unset


                // MARK: Fabrics

                static func from(_ frameWidth: KvViewConfiguration.Frame.Size?) -> ColumnWidth {
                    guard let frameWidth else { return .auto }

                    switch (frameWidth.minimum, frameWidth.ideal, frameWidth.maximum) {
                    case (.none, .some(let width), .none):
                        return .fixed(width)

                    case (.some(let min), _, .some(let max)):
                        let ideal = frameWidth.ideal
                        guard min == max,
                              ideal == nil || ideal! == min
                        else { break }

                        return .fixed(min)

                    default:
                        break
                    }

                    return .auto
                }


                // MARK: CSS

                var css: String {
                    switch self {
                    case .auto, .unset:
                        "auto"
                    case .fixed(let value):
                        value.css
                    }
                }


                // MARK: Operations

                static func merge(_ lhs: inout ColumnWidth, with rhs: ColumnWidth) {
                    switch lhs {
                    case .auto:
                        // Auto can't change.
                        return

                    case .fixed(let value):
                        switch rhs {
                        case .auto:
                            break
                        case .fixed(let rhs):
                            guard value != rhs else { return /* Nothing to do */ }
                        case .unset:
                            return /* Unset values are ignored */
                        }
                        lhs = .auto

                    case .unset:
                        switch rhs {
                        case .unset:
                            return /* Unset values are ignored */
                        default:
                            lhs = rhs
                        }
                    }
                }

            }


            // MARK: Operations

            /// Appends a row and returns the row token.
            fileprivate func nextRow() -> Row {
                defer { nextRowIndex += 1 }

                return Row(at: nextRowIndex, in: self)
            }


            fileprivate func processCell(at index: Int, width: ColumnWidth) {
                switch index < columnWidths.endIndex {
                case true:
                    ColumnWidth.merge(&columnWidths[index] , with: width)

                case false:
                    // Missing elements
                    if columnWidths.count < index {
                        columnWidths.append(contentsOf: repeatElement(.auto, count: index - columnWidths.count))
                    }
                    columnWidths.append(width)
                }
            }


            // MARK: .Row

            /// It's designated to be passed to the child html representation contexts.
            class Row {

                let index: Int

                /// This flag is set to `true` each time ``nextGridRow`` is called.
                /// So an arbitrary view fills entire row.
                /// This flag is changed to `false` for ``KvGridRow`` view, so it's children are processed as cells in a row.
                private(set) var singleCellFlag = true
                private(set) var nextCellIndex = 0


                fileprivate init(at index: Int, in grid: Grid) {
                    self.index = index
                    self.grid = grid
                }


                private weak var grid: Grid?


                // MARK: Operations

                func clearSingleCellFlag() {
                    singleCellFlag = false
                }


                func addCell(with viewConfiguration: KvViewConfiguration?) {
                    let span = viewConfiguration?.gridCellColumnSpan ?? 1

                    switch span <= 1 {
                    case true:
                        assert(span == 1)
                        addCell(.from(viewConfiguration?.frame?.width))

                    case false:
                        (0 ..< span).forEach { _ in
                            addCell(.unset)
                        }
                    }
                }


                private func addCell(_ width: ColumnWidth) {
                    grid?.processCell(at: nextCellIndex, width: width)

                    nextCellIndex += 1
                }

            }

        }

    }



    // MARK: .Options

    struct Options : OptionSet {

        static let noContainer = Self(rawValue: 1 << 0)


        let rawValue: UInt8

    }



    // MARK: Operations

    /// Current localization context.
    var localizationContext: KvLocalization.Context {
        environmentNode?.values.localization ?? html.localizationContext
    }


    /// Current default value for optional values of `Bundle` type.
    var defaultBundle: Bundle {
        environmentNode?.values.defaultBundle ?? .main
    }



    func representation(
        containerAttributes: ContainerAttributes? = nil,
        htmlAttributes: KvHtmlKit.Attributes? = nil,
        options: Options = [ ],
        _ body: (KvHtmlRepresentationContext, borrowing KvHtmlKit.Attributes?) -> KvHtmlRepresentation.Fragment
    ) -> KvHtmlRepresentation.Fragment {
        // Here `self.containerAttributes` is passed to apply it in the extracted CSS.
        var context = self.descendant(containerAttributes: self.containerAttributes)

        // TODO: Pass frame CSS to descendant context in some cases.
        let needsContainer = !options.contains(.noContainer) && viewConfiguration?.frame != nil
        let containerHtmlAttributes: KvHtmlKit.Attributes?

        switch consume needsContainer {
        case true:
            containerHtmlAttributes = context.extractHtmlAttributes()

            context = context.descendant()

        case false:
            containerHtmlAttributes = nil
        }

        var fragment : KvHtmlRepresentation.Fragment
        do {
            let innerCSS = context.extractHtmlAttributes(mergedWith: htmlAttributes)

            context.containerAttributes = containerAttributes

            // - NOTE: `self.viewConfiguration` is important.
            fragment = body(context, innerCSS)
        }

        if let wrappingBlock = self.containerAttributes?.wrapperBlock {
            fragment = wrappingBlock(containerHtmlAttributes ?? .empty, fragment)
        }
        else if let containerHtmlAttributes {
            fragment = .tag(.div, attributes: containerHtmlAttributes, innerHTML: fragment)
        }

        return fragment
    }



    /// - Parameter containerAttributes: Context of container the resulting context is inside. If `nil` then the receiver's container attributes are inherited.
    /// - Parameter htmlAttributes: Attributes to merge with the receiver's attributes.
    ///
    /// - Returns: New context with given values and optionally inherited values.
    func descendant(environmentNode: EnvironmentNode? = nil,
                    containerAttributes: ContainerAttributes? = nil,
                    viewConfiguration: KvViewConfiguration? = nil,
                    htmlAttributes: KvHtmlKit.Attributes? = nil
    ) -> KvHtmlRepresentationContext {
        let htmlAttributes = KvHtmlKit.Attributes.union(self.htmlAttributes, htmlAttributes)

        return .init(html: html,
                     environmentNode: environmentNode ?? self.environmentNode,
                     containerAttributes: containerAttributes,
                     viewConfiguration: viewConfiguration ?? self.viewConfiguration,
                     htmlAttributes: htmlAttributes)
    }


    /// If *environment* contains view configuration
    /// then this method produces descendant context where view configuration is merged or replaced with given value.
    /// If it's impossible to merge then replaced view configuration is converted to CSS and the result is written into *extractedHtmlAttributes*.
    ///
    /// - Returns: The resulting context.
    func descendant(environment: KvEnvironmentValues,
                    extractedHtmlAttributes: inout KvHtmlKit.Attributes?
    ) -> KvHtmlRepresentationContext {
        let descendant: KvHtmlRepresentationContext

        let environmentNode = EnvironmentNode(environment, parent: environmentNode)


        func Descendant(_ viewConfiguration: KvViewConfiguration? = nil) -> KvHtmlRepresentationContext {
            // Container is passed to descendant in this case.
            self.descendant(environmentNode: environmentNode,
                            containerAttributes: containerAttributes,
                            viewConfiguration: viewConfiguration ?? self.viewConfiguration)
        }


        switch KvViewConfiguration.merged(environmentNode.values.viewConfiguration, over: self.viewConfiguration) {
        case .merged(let mergeResult):
            descendant = Descendant(mergeResult)

        case .incompatibility:
            // The receiver is cloned to extract HTML attributes then.
            descendant = Descendant()

            extractedHtmlAttributes = descendant.extractHtmlAttributes()

            descendant.viewConfiguration = environmentNode.values.viewConfiguration
            descendant.containerAttributes = nil
        }

        return descendant
    }


    /// Produces descendant context for grid rows.
    func gridRowDescendant(_ verticalAlignment: KvVerticalAlignment?) -> KvHtmlRepresentationContext {
        // Container context is passed to reset it later.
        let context = self.descendant(containerAttributes: containerAttributes)

        // Container context is changed here.
        if let gridAttributes = context.extractGridHtmlAttributes(verticalAlignment, clearSingleCellFlag: true) {
            context.push(htmlAttributes: gridAttributes)
        }

        return context
    }



    /// - Returns: Extracted the receiver's HTML attributes optionally merged with given *attributes*.
    ///
    /// - Note: The receiver's contents related to HTML attributes are reset.
    /// - Important: Extraction of HTML has some side effects.
    private func extractHtmlAttributes(mergedWith attributes: consuming KvHtmlKit.Attributes? = nil) -> KvHtmlKit.Attributes? {
        var htmlAttributes = KvHtmlKit.Attributes.union(viewConfiguration?.htmlAttributes(in: self), self.htmlAttributes)


        func Accumulate(_ attributes: KvHtmlKit.Attributes) {
            htmlAttributes?.formUnion(attributes) ?? (htmlAttributes = attributes)
        }


        if let gridAttributes = extractGridHtmlAttributes() {
            Accumulate(gridAttributes)
        }
        if let attributes = attributes {
            Accumulate(attributes)
        }

        self.viewConfiguration = nil
        self.htmlAttributes = nil

        return htmlAttributes
    }


    private func extractGridHtmlAttributes(_ verticalAlignment: KvVerticalAlignment? = nil, clearSingleCellFlag: Bool = false) -> KvHtmlKit.Attributes? {
        let gridRow: ContainerAttributes.Grid.Row

        switch containerAttributes?.layout {
        case .grid(_):
            guard let (rowContainer, row) = containerAttributes?.nextGridRow() else { return nil }
            containerAttributes = rowContainer
            gridRow = row
        case .gridRow(let row):
            row.addCell(with: viewConfiguration)
            gridRow = row
        case .none:
            return nil
        }

        if clearSingleCellFlag {
            gridRow.clearSingleCellFlag()
        }

        var attributes = KvHtmlKit.Attributes {
            $0.append(optionalStyles: "grid-row:\(gridRow.index + 1)",
                      gridRow.singleCellFlag ? "grid-column:1/-1" : nil)
        }

        if let flexClass = verticalAlignment.map({ html.cssFlexClass(for: $0, as: .crossSelf) }) {
            attributes.insert(classes: flexClass)
        }

        return attributes
    }


    func push(environment: KvEnvironmentValues) {
        environmentNode = .init(environment, parent: environmentNode)
    }


    /// Merges given *htmlAttributes* into the receiver's CSS attributes.
    private func push(htmlAttributes: consuming KvHtmlKit.Attributes) {
        self.htmlAttributes?.formUnion(htmlAttributes)
        ?? (self.htmlAttributes = htmlAttributes)
    }

}
