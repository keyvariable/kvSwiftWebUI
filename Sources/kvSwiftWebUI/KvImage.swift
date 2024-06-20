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
//  KvImage.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 14.11.2023.
//

import Foundation

import kvCssKit



public typealias Image = KvImage



// TODO: DOC
/// - Tip: Use ``accessibilityLabel(_:)-283fr`` modifier to provide value for *alt* HTML attribute. It matters for SEO and screen readers.
public struct KvImage : KvView {

    @usableFromInline
    let resourceSelector: KvImageResource.Selector

    @usableFromInline
    let bundle: Bundle?


    @usableFromInline
    var configuration: Configuration = .init()



    // TODO: DOC
    @inlinable
    public init(_ name: String, bundle: Bundle? = nil) { self.init(
        selector: .init(name: name),
        bundle: bundle
    ) }


    // TODO: DOC
    @inlinable
    public init(_ resource: KvImageResource) { self.init(selector: resource.selector, bundle: resource.bundle) }


    @usableFromInline
    init(selector: KvImageResource.Selector, bundle: Bundle?) {
        resourceSelector = selector
        self.bundle = bundle
    }



    // MARK: .Configuration

    @usableFromInline
    struct Configuration {

        private var values: [Key : Any] = [:]


        // MARK: .Key

        enum Key : Hashable {
            case accessibilityLabel
            case renderingMode
            case resizingMode
        }


        // MARK: Properties

        private subscript<T>(key: Key) -> T? {
            get { values[key] as! T? }
            set { values[key] = newValue }
        }


        @usableFromInline
        var accessibilityLabel: KvText? {
            get { self[.accessibilityLabel] }
            set { self[.accessibilityLabel] = newValue }
        }

        @usableFromInline
        var renderingMode: TemplateRenderingMode? {
            get { self[.renderingMode] }
            set { self[.renderingMode] = newValue }
        }

        @usableFromInline
        var resizingMode: ResizingMode? {
            get { self[.resizingMode] }
            set { self[.resizingMode] = newValue }
        }

    }



    // MARK: .ResizingMode

    // TODO: DOC
    public enum ResizingMode : Hashable {

        // TODO: DOC
        case stretch
        // TODO: DOC
        case tile

    }



    // MARK: .TemplateRenderingMode

    // TODO: DOC
    public enum TemplateRenderingMode : Hashable {

        // TODO: DOC
        case original
        // TODO: DOC
        case template

    }



    // MARK: : KvView

    public var body: KvNeverView { Body() }



    // MARK: Modifiers

    @usableFromInline
    consuming func modified(with transform: (inout Configuration) -> Void) -> KvImage {
        var copy = self
        transform(&copy.configuration)
        return copy
    }


    /// This modifier provides value of accessibility label.
    /// Accessibility labels for images are used as values of *alt* HTML attribute.
    @inlinable
    public consuming func accessibilityLabel(_ label: KvText) -> KvImage { modified {
        $0.accessibilityLabel = label
    } }


    /// An overload of ``accessibilityLabel(_:)-283fr`` modifier.
    @inlinable
    public consuming func accessibilityLabel(_ label: KvLocalizedStringKey) -> KvImage { accessibilityLabel(Text(label)) }


    /// An overload of ``accessibilityLabel(_:)-283fr`` modifier.
    @_disfavoredOverload
    @inlinable
    public consuming func accessibilityLabel<S>(_ label: S) -> KvImage
    where S : StringProtocol
    { accessibilityLabel(Text(label)) }


    // TODO: DOC
    @inlinable
    public consuming func renderingMode(_ renderingMode: TemplateRenderingMode?) -> KvImage { modified {
        $0.renderingMode = renderingMode
    } }


    // TODO: DOC
    @inlinable
    public consuming func resizable(resizingMode: ResizingMode = .stretch) -> KvImage { modified {
        $0.resizingMode = resizingMode
    } }

}



// MARK: : KvHtmlRenderable

extension KvImage : KvHtmlRenderable {

    func renderHTML(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        switch configuration.renderingMode {
        case .original, nil:
            return context.representation { context, htmlAttributes in
                renderContentHTML(in: context,
                                  htmlAttributes: htmlAttributes,
                                  alignment: context.environmentNode?.values.viewConfiguration?.frame?.alignment)
            }

        case .template:
            return context.representation { context, htmlAttributes in
                let alignment = context.environmentNode?.values.viewConfiguration?.frame?.alignment
                let mask = cssBackground(in: context, alignment: alignment)

                let resizingHtmlAttributes: KvHtmlKit.Attributes? = (configuration.resizingMode != nil
                                                                     ? .init { $0.insert(classes: "resizable") }
                                                                     : nil)

                let hiddenContentAttributes: KvHtmlKit.Attributes = .union(
                    .init { $0.append(styles: "display:block;visibility:hidden") },
                    resizingHtmlAttributes
                )
                var fragment = context
                    .representation(htmlAttributes: consume hiddenContentAttributes) { context, htmlAttributes in
                        renderContentHTML(in: context, htmlAttributes: htmlAttributes, alignment: alignment)
                    }

                // Two containers are used to separate context's background and the mask background.

                fragment = .tag(
                    .div,
                    attributes: .union(
                        .init {
                            $0.append(optionalStyles: context.environmentNode?.values.foregroundStyle?.cssBackgroundStyle(context.html, nil),
                                      "-webkit-mask:\(mask.css);mask:\(mask.css)")
                        },
                        resizingHtmlAttributes
                    ),
                    innerHTML: fragment
                )

                return .tag(.div, attributes: .union(htmlAttributes, resizingHtmlAttributes) ?? .empty, innerHTML: fragment)
            }
        }
    }


    private func cssBackground(in context: KvHtmlRepresentationContext, alignment: KvAlignment?) -> KvCssBackground {
        let size: KvCssBackground.Size?
        let `repeat`: KvCssBackground.Repeat

        switch configuration.resizingMode {
        case .none, .stretch:
            (size, `repeat`) = (.contain, .noRepeat)
        case .tile:
            (size, `repeat`) = (nil, .repeat)
        }

        return .init(source: .uri(context.html.uri(for: resource(in: context))),
                     position: alignment?.cssBackgroundPosition,
                     size: size,
                     repeat: `repeat`)
    }


    private func renderContentHTML(
        in context: KvHtmlRepresentationContext,
        htmlAttributes: borrowing KvHtmlKit.Attributes?,
        alignment: @autoclosure () -> KvAlignment?
    ) -> KvHtmlRepresentation.Fragment {
        switch configuration.resizingMode {
        case .stretch:
            renderImgHTML(
                in: context,
                htmlAttributes: .union(
                    htmlAttributes,
                    .init {
                        $0.insert(classes: "resizable")
                        $0.append(optionalStyles: alignment()?.cssObjectPosition, "object-fit:contain")
                    }
                )
            )

        case .tile:
            renderDivHTML(in: context, alignment: alignment(), htmlAttributes: htmlAttributes)

        case nil:
            renderImgHTML(in: context, htmlAttributes: htmlAttributes)
        }
    }


    private func renderImgHTML(
        in context: KvHtmlRepresentationContext,
        htmlAttributes: borrowing KvHtmlKit.Attributes?
    ) -> KvHtmlRepresentation.Fragment {
        .tag(
            .img,
            attributes: .union(
                htmlAttributes,
                .init {
                    $0.set(src: context.html.uri(for: resource(in: context)))
                    if let value = configuration.accessibilityLabel?.plainText(in: context.localizationContext) {
                        $0[.alt] = .string(value)
                    }
                }
            )
        )
    }


    private func renderDivHTML(
        in context: KvHtmlRepresentationContext,
        alignment: KvAlignment?,
        htmlAttributes: borrowing KvHtmlKit.Attributes?
    ) -> KvHtmlRepresentation.Fragment {
        .tag(
            .div,
            attributes: .union(
                htmlAttributes,
                .init {
                    $0.insert(classes: "resizable")
                    $0.append(styles: "background:\(cssBackground(in: context, alignment: alignment).css)")
                }
            )
        )
    }


    private func resource(in context: KvHtmlRepresentationContext) -> KvImageResource {
        .init(selector: resourceSelector,
              bundle: bundle ?? context.defaultBundle)
    }

}
