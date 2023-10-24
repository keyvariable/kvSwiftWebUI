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
//  KvModifiedView.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 01.11.2023.
//

import kvCssKit



// MARK: - KvViewConfiguration

@usableFromInline
struct KvViewConfiguration : KvConfiguration {

    @usableFromInline
    var navigation: Navigation?

    @usableFromInline
    var appearance: Appearance? {
        didSet { didSetAppearance() }
    }

    @usableFromInline
    var container: Container?

    @usableFromInline
    var gridCell: GridCell?

    @usableFromInline
    var environment: KvEnvironmentValues?



    init(navigation: Navigation? = nil,
         appearance: Appearance? = nil,
         container: Container? = nil,
         gridCell: GridCell? = nil,
         environment: KvEnvironmentValues? = nil
    ) {
        self.navigation = navigation
        self.appearance = appearance
        self.container = container
        self.gridCell = gridCell
        self.environment = environment

        didSetAppearance()
    }



    // MARK: : KvConfiguration

    typealias MergeResult = KvMergeResult<Self>
    typealias OptionalMergeResult = KvMergeResult<Self?>


    static func merged(_ addition: Self, over base: Self) -> MergeResult {
        let navigation = Navigation.merged(addition.navigation, over: base.navigation)
        let appearance = Appearance.merged(addition.appearance, over: base.appearance)
        let gridCell = GridCell.merged(addition.gridCell, over: base.gridCell)

        // - NOTE: containers are merged in the reverse direction.
        guard case .merged(let container) = Container.merged(base.container, over: addition.container)
        else { return .incompatibility }

        let environment = addition.environment.map {
            $0.parent = base.environment
            return $0
        }
        ?? base.environment

        return .merged(.init(navigation: navigation,
                             appearance: appearance,
                             container: container,
                             gridCell: gridCell,
                             environment: environment))
    }



    // MARK: CSS

    func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes? {
        .union(
            .union(appearance?.cssAttributes(in: context),
                   container?.cssAttributes(in: context)),
            gridCell?.cssAttributes(in: context)
        )
    }



    // MARK: Operations

    private mutating func didSetAppearance() {
        updateEnvironment()
    }


    private mutating func modifyEnvironment(transform: (KvEnvironmentValues) -> Void) {
        switch environment {
        case .none:
            environment = .init(transform)
        case .some(let environment):
            transform(environment)
        }
    }


    private mutating func updateEnvironment() {
        let foregroundStyle = appearance?.foregroundStyle
        let textStyle = appearance?.font?.textStyle

        modifyEnvironment { environment in
            if let foregroundStyle {
                environment.foregroundStyle = foregroundStyle
            }
            if let textStyle {
                environment.textStyle = textStyle
            }
        }
    }



    // MARK: .Navigation

    @usableFromInline
    struct Navigation : KvConfiguration {

        @usableFromInline
        var title: KvText?


        // MARK: : KvConfiguration

        typealias MergeResult = Self
        typealias OptionalMergeResult = Self?


        static func merged(_ addition: Self, over base: Self) -> MergeResult {
            .init(
                title: base.title?.isEmpty == false ? base.title : addition.title       // Non-empty title is not changed.
            )
        }

    }


    // MARK: .Appearance

    @usableFromInline
    struct Appearance : KvConfiguration {

        @usableFromInline
        var foregroundStyle: KvAnyShapeStyle?


        @usableFromInline
        var font: KvFont?

        @usableFromInline
        var multilineTextAlignment: KvTextAlignment?

        @usableFromInline
        var textCase: KvText.Case?


        @usableFromInline
        var fixedSize: FixedSize


        init(foregroundStyle: KvAnyShapeStyle? = nil,
             font: KvFont? = nil, multilineTextAlignment: KvTextAlignment? = nil, textCase: KvText.Case? = nil,
             fixedSize: FixedSize = [ ]
        ) {
            self.foregroundStyle = foregroundStyle
            self.font = font
            self.multilineTextAlignment = multilineTextAlignment
            self.textCase = textCase
            self.fixedSize = fixedSize
        }


        // MARK: : KvConfiguration

        typealias MergeResult = Self
        typealias OptionalMergeResult = Self?


        static func merged(_ addition: Self, over base: Self) -> MergeResult {
            let foregroundStyle = addition.foregroundStyle ?? base.foregroundStyle
            let font = addition.font ?? base.font
            let multilineTextAlignment = addition.multilineTextAlignment ?? base.multilineTextAlignment
            let textCase = addition.textCase ?? base.textCase
            let fixedSize: FixedSize = base.fixedSize.union(addition.fixedSize)

            return .init(
                foregroundStyle: foregroundStyle,
                font: font,
                multilineTextAlignment: multilineTextAlignment,
                textCase: textCase,
                fixedSize: fixedSize
            )
        }


        // MARK: CSS

        func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes {
            let color: KvHtmlBytes? = foregroundStyle?.cssForegroundStyle(context.html, nil)
            let font: KvHtmlBytes? = font?.cssStyle(in: context.html)
            let textAlign: KvHtmlBytes? = multilineTextAlignment.map { "text-align:\($0.cssTextAlign.css)" }
            let textTransform: KvHtmlBytes? = textCase.map { "text-transform:\($0.cssTextTransform)" }
            let fixedSize: KvHtmlBytes? = fixedSize.cssFlexShrink(in: context)

            return .init(styles: color, font, textAlign, textTransform, fixedSize)
        }


        // MARK: .FixedSize

        @usableFromInline
        struct FixedSize : OptionSet {

            @usableFromInline
            static let horizontal = Self(rawValue: 1 << 0)

            @usableFromInline
            static let vertical = Self(rawValue: 1 << 1)


            // MARK: OptionSet

            @usableFromInline let rawValue: UInt

            @usableFromInline init(rawValue: UInt) { self.rawValue = rawValue }


            // MARK: Operations

            func cssFlexShrink(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlBytes? {
                guard (contains(.horizontal) && context.containerAttributes?.layoutDirection == .horizontal)
                        || (contains(.vertical) && context.containerAttributes?.layoutDirection == .vertical)
                else { return nil }

                return "flex-shrink:0"
            }

        }

    }



    // MARK: .Container

    @usableFromInline
    struct Container : KvConfiguration {

        @usableFromInline
        private(set) var padding: KvCssEdgeInsets?

        @usableFromInline
        private(set) var frame: Frame?

        @usableFromInline
        private(set) var background: KvAnyShapeStyle?

        @usableFromInline
        private(set) var clipShape: KvClipShape?



        private var constraints: Constraints = [ ]



        init(padding: KvCssEdgeInsets? = nil, frame: Frame? = nil, background: KvAnyShapeStyle? = nil, clipShape: KvClipShape? = nil) {
            self.padding = padding
            self.frame = frame
            self.background = background
            self.clipShape = clipShape

            resetConstraints()
        }



        // MARK: : KvConfiguration

        typealias MergeResult = KvMergeResult<Self>
        typealias OptionalMergeResult = KvMergeResult<Self?>


        static func merged(_ addition: Self, over base: Self) -> MergeResult {
            var result = base

            // TODO: Optimize
            // Order of modifications matters.
            guard addition.padding == nil || result.modify(padding: addition.padding!) == nil,
                  addition.frame == nil || result.modify(frame: addition.frame!) == nil,
                  addition.background == nil || result.modify(background: addition.background!) == nil
            else { return .incompatibility }

            return .merged(result)
        }



        // MARK: .Constraints

        private struct Constraints : OptionSet {

            static let immutablePadding = Self(rawValue: 1 << 0)
            static let immutableFrame = Self(rawValue: 1 << 1)
            static let immutableBackground = Self(rawValue: 1 << 2)

            let rawValue: UInt

        }



        // MARK: Operations

        /// - Returns: An instance with rejected content.
        @usableFromInline
        mutating func modify(padding: KvCssEdgeInsets) -> Self? {
            guard !constraints.contains(.immutablePadding) else { return .init(padding: padding) }

            self.padding = self.padding + padding
            return nil
        }


        /// - Returns: An instance with rejected content.
        @usableFromInline
        mutating func modify(paddingBlock: (KvCssEdgeInsets?) -> KvCssEdgeInsets?) -> Self? {
            guard !constraints.contains(.immutablePadding) else { return .init(padding: paddingBlock(nil)) }

            self.padding = paddingBlock(self.padding)
            return nil
        }


        /// - Returns: An instance with rejected content.
        @usableFromInline
        mutating func modify(frame: Frame) -> Self? {
            guard !constraints.contains(.immutableFrame),
                  self.frame == nil // Frame can't be replaced.
            else { return .init(frame: frame) }

            self.frame = frame
            resetConstraints()
            return nil
        }


        /// - Returns: An instance with rejected content.
        @usableFromInline
        mutating func modify(background: KvAnyShapeStyle) -> Self? {
            guard !constraints.contains(.immutableBackground) else { return .init(background: background) }

            self.background = background
            resetConstraints()
            return nil
        }


        /// - Returns: An instance with rejected content.
        @usableFromInline
        mutating func modify(clipShape: KvClipShape) -> Self? {
            // Clipshape can't be replaced.
            guard self.clipShape == nil else { return .init(clipShape: clipShape) }

            self.clipShape = clipShape
            resetConstraints()
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



        // MARK: CSS

        func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes {
            let backgroundColor: KvHtmlBytes? = background?.cssBackgroundStyle(context.html, nil)
            let padding: KvHtmlBytes? = padding.map { "padding:\($0.css)" }

            var attributes = KvHtmlKit.CssAttributes(styles: backgroundColor, padding)

            if let frameCSS = frame?.cssAttributes(in: context) {
                attributes.formUnion(frameCSS)
            }

            if let clipShapeAttributes = clipShape?.css {
                attributes.formUnion(clipShapeAttributes)
            }

            return attributes
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

    }



    // MARK: .Layout

    @usableFromInline
    struct GridCell : KvConfiguration {

        @usableFromInline
        var gridColumnAlignment: KvHorizontalAlignment?

        @usableFromInline
        var gridCellColumnSpan: Int?


        init(gridColumnAlignment: KvHorizontalAlignment? = nil, gridCellColumnSpan: Int? = nil) {
            self.gridColumnAlignment = gridColumnAlignment
            self.gridCellColumnSpan = gridCellColumnSpan
        }


        // MARK: : KvConfiguration

        typealias MergeResult = Self
        typealias OptionalMergeResult = Self?


        static func merged(_ addition: Self, over base: Self) -> MergeResult {
            .init(gridColumnAlignment: addition.gridColumnAlignment ?? base.gridColumnAlignment,
                  gridCellColumnSpan: addition.gridCellColumnSpan ?? base.gridCellColumnSpan)
        }


        // MARK: CSS

        func cssAttributes(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlKit.CssAttributes {
            .init(classes: gridColumnAlignment.map { context.html.cssFlexClass(for: $0, as: .mainSelf) },
                  styles: gridCellColumnSpan.map { "grid-column:span \($0)" })
        }

    }

}



// MARK: - KvModifiedView

struct KvModifiedView : KvView {

    typealias Configuration = KvViewConfiguration

    typealias SourceProvider = () -> any KvView



    var configuration: Configuration

    let sourceProvider: SourceProvider



    init(configuration: Configuration = .init(), source: @escaping SourceProvider) {
        self.configuration = configuration
        self.sourceProvider = source
    }



    // MARK: : KvView

    var body: KvNeverView { Body() }



    // MARK: Operations

    @usableFromInline
    consuming func modified(_ transform: (inout Configuration) -> Configuration?) -> Self {
        var copy = self

        switch transform(&copy.configuration) {
        case .none:
            return copy
        case .some(let containerConfiguration):
            return .init(configuration: containerConfiguration, source: { copy })
        }
    }



    // MARK: HTML Representation

    func htmlRepresentation(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
        var containerCSS: KvHtmlKit.CssAttributes?
        let context = context.descendant(viewConfiguration: configuration, droppedCssAttributes: &containerCSS)

        var representation = sourceProvider().htmlRepresentation(in: context)

        // Container with extracted CSS attributes.
        if let containerCSS = containerCSS {
            representation = representation.mapBytes { .tag(.div, css: containerCSS, innerHTML: $0) }
        }

        if let title = configuration.navigation?.title,
           !title.isEmpty
        {
            representation.title = title.escapedPlainBytes
        }

        return representation
    }

}
