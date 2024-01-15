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

@usableFromInline
typealias KvViewConfiguration = KvEnvironmentValues.ViewConfiguration



struct KvModifiedView : KvView {

    typealias Environment = KvEnvironmentValues

    typealias SourceProvider = () -> any KvView



    private(set) var environment: Environment

    let sourceProvider: SourceProvider



    init(environment: Environment = .init(), source: @escaping SourceProvider) {
        self.environment = environment
        self.sourceProvider = source

        // Assuming KvModifiedView is created to have some view configuration.
        if self.environment.viewConfiguration == nil {
            self.environment.viewConfiguration = .init()
        }
    }



    // MARK: : KvView

    var body: KvNeverView { Body() }



    // MARK: Operations

    @usableFromInline
    consuming func mapEnvironment(_ transform: (inout KvEnvironmentValues) -> Void) -> Self {
        var copy = self
        transform(&copy.environment)
        return copy
    }


    /// - Parameter transform: Argument is always non-nil.
    @usableFromInline
    consuming func mapConfiguration(_ transform: (inout KvViewConfiguration?) -> Void) -> Self {
        var copy = self
        assert(copy.environment.viewConfiguration != nil)
        transform(&copy.environment.viewConfiguration)
        return copy
    }


    /// - Parameter transform: Argument is always non-nil.
    @usableFromInline
    consuming func mapConfiguration(_ transform: (inout KvViewConfiguration?) -> KvViewConfiguration?) -> Self {
        var copy = self
        assert(copy.environment.viewConfiguration != nil)
        return switch transform(&copy.environment.viewConfiguration) {
        case .none: copy
        case .some(let containerConfiguration): .init(environment: .init(containerConfiguration), source: { copy })
        }
    }



    // MARK: HTML Representation

    func htmlRepresentation(in context: KvHtmlRepresentationContext) -> KvHtmlRepresentation.Fragment {
        var containerCSS: KvHtmlKit.CssAttributes?
        let context = context.descendant(environment: environment, extractedCssAttributes: &containerCSS)

        var fragment = sourceProvider().htmlRepresentation(in: context)

        // Container with extracted CSS attributes.
        if let containerCSS = containerCSS {
            fragment = .tag(.div, css: containerCSS, innerHTML: fragment)
        }

        if let title = environment.viewConfiguration?.navigationTitle,
           !title.isEmpty
        {
            fragment.navigationTitle = title
        }

        if let destinations = environment.viewConfiguration?.navigationDestinations {
            fragment.navigationDestinations = .merged(fragment.navigationDestinations, destinations)
        }

        return fragment
    }

}
