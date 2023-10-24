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
//  KvView.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 24.10.2023.
//

public typealias View = KvView



// TODO: DOC
public protocol KvView {

    /// It's inferred from your implementation of the required property ``KvView/body-swift.property``.
    associatedtype Body : KvView


    /// It's a place to define view's contents.
    @KvViewBuilder
    var body: Body { get }

}



// MARK: HTML Representation

extension KvView {

    func htmlRepresentation(in context: borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation {
        typealias RepresentationProvider = KvHtmlRepresentationModifiers.RepresentationProvider

        let makeInitialRepresentation: RepresentationProvider = { context in
            // Providing source to environment bindings.
            self.forEachEnvironmentBinding { $0.source = context.environment }

            return switch self {
            case let modifiedView as KvModifiedView:
                modifiedView.htmlRepresentation(in: context)
            case let htmlRenderable as KvHtmlRenderable:
                htmlRenderable.renderHTML(in: context)
            default:
                self.body.htmlRepresentation(in: context)
            }
        }

        let sourceEnvironment = context.environment

        let provider: RepresentationProvider
        do {
            var accumulator = makeInitialRepresentation

            self.forEachEnvironmentBinding { binding in
                switch binding.keyPath {
                case \.horizontalSizeClass:
                    // If size class is provided then no modifications required.
                    guard sourceEnvironment.horizontalSizeClass == nil else { break }

                    accumulator = KvHtmlRepresentationModifiers.automaticSizeClass(base: accumulator)

                default: break
                }
            }

            provider = accumulator
        }

        return provider(context)
    }



    private func forEachEnvironmentBinding(_ body: (KvEnvironmentProtocol) -> Void) {
        Mirror(reflecting: self).children.forEach {
            guard let value = $0.value as? KvEnvironmentProtocol else { return }

            body(value)
        }
    }

}



// MARK: - KvHtmlRepresentationModifiers

fileprivate struct KvHtmlRepresentationModifiers { private init() { }

    typealias RepresentationProvider = (borrowing KvHtmlRepresentationContext) -> KvHtmlRepresentation



    static func automaticSizeClass(base baseProvider: @escaping RepresentationProvider) -> RepresentationProvider {
        return { context in
            // Separate container for injected values preventing change of the source containers.
            let envValues = KvEnvironmentValues()

            assert(!KvUserInterfaceSizeClass.allCases.isEmpty)

            return .joined(KvUserInterfaceSizeClass.allCases.lazy.map {
                envValues.horizontalSizeClass = $0

                return baseProvider(context.descendant(environment: envValues,
                                                       containerAttributes: context.containerAttributes,    // Preserving container context.
                                                       cssAttributes: .init(classes: $0.cssHorizontalClass)))
            })
        }
    }

}
