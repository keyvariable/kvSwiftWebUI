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
//  KvCssAsset.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 03.11.2023.
//

import Foundation



class KvCssAsset {

    /// It's weak to prevent retain cycles.
    weak var parent: Prototype?



    init(parent: Prototype?) {
        self.parent = parent
    }



    /// [MediaQuery? : [Scope? : [ID : CSS]]].
    ///
    /// - Note: Entry IDs are used to prevent duplicated declarations and sort declarations in the resulting CSS code.
    ///
    /// - Note: `nil` scope means that the declaration don't require selector (e.g. it already has a selector).
    ///         If selector is provided then declarations are grouped by this selector.
    private typealias Declarations = [MediaQuery? : [String? : [EntryID : String]]]


    /// IDs of entries in ``declarations``.
    private var entryIDs: Set<EntryID> = .init()

    /// Entry IDs are used to prevent duplicated declarations and sort declarations in the resulting CSS code.
    private var declarations: Declarations = .init()



    // MARK: .Prototype

    class Prototype {

        typealias EntryID = KvCssAsset.EntryID


        /// It's weak to prevent retain cycles.
        weak var parent: Prototype?

        let resource: KvHtmlResource


        init(parent: Prototype?, resource: KvHtmlResource, entryIDs: Set<EntryID> = [ ]) {
            self.parent = parent
            self.resource = resource
            self.entryIDs = entryIDs
        }


        private let entryIDs: Set<EntryID>


        // MARK: Predefined Assets

        static let foundation: Prototype = .init(
            parent: nil,
            resource: .css(
                .local(.url(Bundle.module.url(forResource: "foundation", withExtension: "css", subdirectory: "html/css")!),
                       "z8GEYWllTRKr13Y4LLr2MA.css")
            )
        )


        // MARK: Operations

        func contains(_ entryID: EntryID) -> Bool { entryIDs.contains(entryID) }

    }



    // MARK: .MediaQuery

    private enum MediaQuery : Hashable {

        case darkColorTheme
        case raw(String)


        // MARK: CSS

        var cssQuery: String {
            switch self {
            case .darkColorTheme: "(prefers-color-scheme: dark)"
            case .raw(let string): string
            }
        }

    }



    // MARK: .EntryID

    enum EntryID : Hashable, Comparable {

        case color(id: String)
        case flexClasses
        case fontResource(name: String, key: KvFontResource.Face.Key)


        // MARK: : Comparable

        private var groupOrderKey: GroupOrderKey {
            switch self {
            case .color(_): .color
            case .flexClasses: .flexClasses
            case .fontResource(_, _): .font
            }
        }


        static func <(lhs: Self, rhs: Self) -> Bool {
            switch lhs {
            case .color(let lhs):
                guard case .color(let rhs) = rhs else { return GroupOrderKey.color < rhs.groupOrderKey }
                return lhs < rhs

            case .flexClasses:
                return lhs.groupOrderKey < rhs.groupOrderKey

            case .fontResource(name: let lName, key: let lKey):
                guard case .fontResource(name: let rName, key: let rKey) = rhs else { return GroupOrderKey.color < rhs.groupOrderKey }

                switch lName.compare(rName) {
                case .orderedAscending: return true
                case .orderedDescending: return false
                case .orderedSame: break
                }

                if lKey.weight < rKey.weight { return true }
                else if rKey.weight < lKey.weight { return false }

                return !lKey.isItalic && rKey.isItalic // false is 0, true is 1
            }
        }


        // MARK: .GroupOrderKey

        private enum GroupOrderKey: UInt, Comparable {

            case color
            case flexClasses
            case font

            // MARK: : Comparable

            static func <(lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

        }

    }



    // MARK: .Entry

    struct Entry {

        typealias ID = EntryID


        let selector: String?
        /// Identifier used to filter duplicates and provide the same CSS for the same declarations.
        let id: ID
        let `default`: () -> String
        /// - Parameter dark: Optional CSS code producing value in dark environment.
        let dark: (() -> String)?


        init(selector: String? = nil, id: ID, default: @escaping () -> String, dark: (() -> String)? = nil) {
            self.selector = selector
            self.id = id
            self.default = `default`
            self.dark = dark
        }

    }



    // MARK: Operations

    var isEmpty: Bool { entryIDs.isEmpty }


    var css: String {

        func CssForMediaQuery(_ mediaQuery: MediaQuery?) -> String {
            let mediaQueryNode = self.declarations[mediaQuery]!


            func CssForSelector(_ selector: String?) -> String {
                let selectorNode = mediaQueryNode[selector]!

                let styles: String = selectorNode.keys
                    .sorted()
                    .lazy.map { selectorNode[$0]! }
                    .joined()

                return switch selector {
                case .none: styles
                case .some(let selector): "\(selector){\(styles)}"
                }
            }


            let styles: String = mediaQueryNode.keys
                .sorted(by: { ($0 ?? "") < ($1 ?? "") })
                .lazy.map(CssForSelector(_:))
                .joined()

            return switch mediaQuery {
            case .none: styles
            case .some(let query): "@media \(query.cssQuery){\(styles)}"
            }
        }


        return declarations.keys
            .sorted(by: { ($0?.cssQuery ?? "") < ($1?.cssQuery ?? "") })
            .lazy.map(CssForMediaQuery(_:))
            .joined()
    }


    /// - Returns: A prototype instance those contents are available as given *resource*.
    func asPrototype(resource: KvHtmlResource) -> Prototype {
        return .init(parent: parent,
                     resource: resource,
                     entryIDs: entryIDs)
    }


    /// - Returns: A CSS asset prototype containing *entity* or `nil` if *entity* has been inserted into the receiver.
    func insert(_ entry: Entry) -> Prototype? {
        do {
            var prototype = parent

            while let asset = prototype {
                if asset.contains(entry.id) {
                    return asset
                }

                prototype = asset.parent
            }
        }

        insert(selector: entry.selector, id: entry.id, declaration: entry.default)

        if let declaration = entry.dark {
            insert(mediaQuery: .darkColorTheme, selector: entry.selector, id: entry.id, declaration: declaration)
        }

        return nil
    }


    /// - Parameter declaration: A block invoked only when the receiver hasn't the declaration.
    private func insert(mediaQuery: MediaQuery? = nil, selector: String? = nil, id: EntryID, declaration: () -> String) {
        entryIDs.insert(id)

        _ = { mediaQueryContainer in
            _ = { container in
                let oldDeclaration = container[id]

                guard oldDeclaration == nil
                else { return assert(oldDeclaration! == declaration(), "Attempt to replace CSS `\(oldDeclaration!)` with `\(declaration())` with «\(id)» ID for \(mediaQuery.map(String.init(describing:)) ?? "`nil`") media query and \(selector.map(String.init(describing:)) ?? "`nil`") selector") }

                /// Leading and trailing whitespace characters are ignored.
                let declaration = declaration().trimmingCharacters(in: .whitespacesAndNewlines)

                /// Empty declarations are ignored.
                guard !declaration.isEmpty else { return }

                container[id] = declaration
            }(&mediaQueryContainer[selector, default: .init()])
        }(&declarations[mediaQuery, default: .init()])
    }

}
