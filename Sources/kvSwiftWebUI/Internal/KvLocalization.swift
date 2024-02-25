//===----------------------------------------------------------------------===//
//
//  Copyright (c) 2024 Svyatoslav Popov (info@keyvar.com).
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
//  KvLocalization.swift
//  kvSwiftWebUI
//
//  Created by Svyatoslav Popov on 05.02.2024.
//

import Foundation

import kvHttpKit



/// This class provides various stuff related to localization of the resources.
///
/// *KvLocalization* caches locales used to translate for language IDs and bundles.
public class KvLocalization {

    init(_ bundle: Bundle) {
        self.bundle = bundle

        languageTags = bundle.localizations
        defaultLanguageTag = bundle.preferredLocalizations.first ?? bundle.localizations.first
    }



    private typealias AcceptLanguageIterator = KvHttpAcceptLanguage.Iterator


    private let bundle: Bundle

    /// Language tags ([RFC 5646](https://www.rfc-editor.org/rfc/rfc5646.html )).
    private let languageTags: [String]
    private let defaultLanguageTag: String?



    // MARK: Operations

    private static func selectLanguageTag(for languageTag: String, in languageTags: [String]) -> Match<MatchRate>? {
        languageTags
            .lazy.compactMap { lt in MatchRate.ofLanguageTags(lt, languageTag).map { Match(languageTag: lt, rate: $0) } }
            .max()
    }


    func selectLanguageTag(forAcceptLanguageHeader value: String) -> String? {
        IteratorSequence(KvLocalization.AcceptLanguageIterator(value))
            .lazy.compactMap { element -> Match<MatchCompositeRate>? in
                switch element.languageTag {
                case .some(let languageTag):
                    KvLocalization.selectLanguageTag(for: languageTag, in: self.languageTags)?
                        .mapRate { .init(rate: $0, languageRank: element.rank) }

                case .wildcard:
                    self.defaultLanguageTag.map {
                        Match(languageTag: $0, rate: .init(rate: .exact, languageRank: element.rank))
                    }
                }
            }
            .max()?
            .languageTag
        ?? defaultLanguageTag
    }


    func forEachLanguageTag(_ body: (String) -> Void) {
        languageTags.forEach(body)
    }


    func context(languageTag: String?) -> Context {
        .init(languageTag: languageTag, primaryBundle: bundle)
    }



    // MARK: .Match

    private struct Match<Rate : Comparable> : Comparable {

        let languageTag: String?
        let rate: Rate


        // MARK: : Equatable

        static func ==(lhs: borrowing Match, rhs: borrowing Match) -> Bool { lhs.rate == rhs.rate }


        // MARK: : Comparable

        static func <(lhs: borrowing Match, rhs: borrowing Match) -> Bool { lhs.rate < rhs.rate }


        // MARK: Operations

        func mapRate<R : Comparable>(_ block: (Rate) -> R) -> Match<R> {
            .init(languageTag: languageTag, rate: block(rate))
        }

    }



    // MARK: .MatchRate

    /// - Note: It's internal to provide access from unit-tests.
    enum MatchRate : Comparable {

        case exact
        /// Associated value is a number of matching leading subtags.
        case partial(Int)


        // MARK: Fabrics

        /// Initializes result of matching two language tags.
        static func ofLanguageTags(_ lhs: String, _ rhs: String) -> MatchRate? {
            var numberOfSubtags = 0


            func MakeResult() -> MatchRate? {
                numberOfSubtags > 0 ? .partial(numberOfSubtags) : nil
            }


            var lhs = lhs.makeIterator()
            var rhs = rhs.makeIterator()

            while let lc = lhs.next() {
                switch rhs.next() {
                case .some(let rc):
                    switch (lc, rc) {
                    case ("-", "-"):
                        numberOfSubtags += 1
                    case ("-", _), (_, "-"):
                        return MakeResult()
                    default:
                        guard lc == rc || String(lc).caseInsensitiveCompare(String(rc)) == .orderedSame
                        else { return MakeResult() }
                    }

                case .none:
                    return lc == "-" ? .partial(numberOfSubtags + 1) : MakeResult()
                }
            }

            switch rhs.next() {
            case nil:
                return .exact
            case "-":
                numberOfSubtags += 1
            default:
                break
            }

            return MakeResult()
        }


        // MARK: : Comparable

        static func <(lhs: MatchRate, rhs: MatchRate) -> Bool {
            switch (lhs, rhs) {
            case (.exact, _): false
            case (.partial(_), .exact): true
            case (.partial(let lhs), .partial(let rhs)): lhs < rhs
            }
        }


        // MARK: Operations

        func compare(_ rhs: MatchRate) -> ComparisonResult {
            switch (self, rhs) {
            case (.exact, .exact): .orderedSame
            case (.exact, .partial(_)): .orderedDescending
            case (.partial(_), .exact): .orderedAscending
            case (.partial(let lhs), .partial(let rhs)):
                lhs < rhs ? .orderedAscending : (lhs == rhs ? .orderedSame : .orderedDescending)
            }
        }

    }



    // MARK: .MatchCompositeRate

    private struct MatchCompositeRate : Comparable {

        let rate: MatchRate
        let languageRank: AcceptLanguageIterator.Element.Rank


        // MARK: : Comparable

        static func <(lhs: borrowing MatchCompositeRate, rhs: borrowing MatchCompositeRate) -> Bool {
            switch lhs.rate.compare(rhs.rate) {
            case .orderedAscending: true
            case .orderedDescending: false
            case .orderedSame: lhs.languageRank < rhs.languageRank
            }
        }

    }



    // MARK: .Context

    /// A context of localization. It resolves localized string resources according to the context's locale.
    ///
    /// Below is an example of common usage:
    /// ```swift
    /// struct HelloView : View {
    ///     @Environment(\.localization) private var localization
    ///
    ///     var body: some View {
    ///         let hello = localization.string(forKey: "hello!")
    ///         Text(verbatim: hello.uppercased())
    ///     }
    /// }
    /// ```
    ///
    /// - Note: ``Text`` view supports localization so in most cases there is no need to access localization context.
    public class Context {

        /// Selected language tag in the primary bundle or `nil` whether localization is enabled.
        /// When localization is disabled, keys of localized resources are used as resolved strings.
        public var languageTag: String? { resolvedBundles.languageTag }


        fileprivate convenience init(languageTag: String?, primaryBundle: Bundle) {
            assert(languageTag == nil || primaryBundle.localizations.contains(languageTag!))

            self.init(primaryBundle: primaryBundle, resolvedBundles: .init(languageTag: languageTag))
        }


        private init(primaryBundle: Bundle, resolvedBundles: ResolvedBundles) {
            self.primaryBundle = primaryBundle
            self.resolvedPrimaryBundle = resolvedBundles[primaryBundle]
            self.resolvedBundles = resolvedBundles
        }


        /// Primary bundle.
        private let primaryBundle: Bundle
        /// Resolved primary bundle.
        private let resolvedPrimaryBundle: Bundle

        /// Cache of resolved bundles.
        private var resolvedBundles: ResolvedBundles


        // MARK: Fabrics

        /// - Returns: A context providing no localization. It just returns the keys.
        static var disabled: Context { .init(languageTag: nil, primaryBundle: .main) }


        // MARK: .ResolvedBundles

        /// It's a class to be shared between contexts.
        private class ResolvedBundles {

            let languageTag: String?


            init(languageTag: String?) {
                self.languageTag = languageTag
            }


            /// Cache of resolved bundles by bundle URLs.
            private var values: [URL : Bundle] = .init()


            // MARK: Operations

            subscript(bundle: Bundle) -> Bundle {
                switch values[bundle.bundleURL] {
                case .some(let bundle):
                    return bundle

                case .none:
                    let resolved = resolve(bundle)
                    values[bundle.bundleURL] = resolved
                    return resolved
                }
            }


            /// - Returns: A child bundle containing localized resources for given *languageTag* or *bundle* otherwise.
            private func resolve(_ bundle: Bundle) -> Bundle {
                guard let languageTag = languageTag.map({
                    KvLocalization.selectLanguageTag(for: $0, in: bundle.localizations)?.languageTag
                    ?? bundle.preferredLocalizations.first
                    ?? bundle.localizations.first
                })
                else { return bundle }

                guard let url = bundle.url(forResource: languageTag, withExtension: "lproj"),
                      let bundle = Bundle(url: consume url)
                else { return bundle }

                return bundle
            }

        }


        // MARK: Operations

        struct Options : OptionSet {

            /// If specified then arguments of type ``KvText`` are replaced with `"%n$T"`.
            static let textPlaceholders = Self(rawValue: 1 << 0)

            let rawValue: UInt

        }


        func with(primaryBundle: Bundle) -> Context {
            guard primaryBundle !== self.primaryBundle else { return self }

            return .init(primaryBundle: primaryBundle, resolvedBundles: resolvedBundles)
        }


        /// - Parameter defaultBundle: Bundle to use when the *resource*'s bundle is `nil`.
        borrowing func string(_ resource: borrowing StringResource, options: Options = [ ]) -> String {
            string(forKey: resource.key,
                   defaultValue: resource.defaultValue,
                   table: resource.table,
                   bundle: resource.bundle,
                   comment: nil,
                   options: options)
        }


        // TODO: stringgen
        /// - Parameter bundle: Optional bundle to take localized string from. If `nil` then the primary bundle is used.
        /// 
        /// - Returns: A resolved localized string in the localization context.
        ///
        /// Method returns first available string of:
        /// 1. localized string from the bundle for the locale;
        /// 2. localized string from the bundle for the first preferred locale;
        /// 3. *defaultValue*;
        /// 4. *key*.
        ///
        /// See documentation of ``Context`` for examples.
        public borrowing func string(forKey key: KvLocalizedStringKey,
                                     defaultValue: String? = nil,
                                     table: String? = nil,
                                     bundle: Bundle? = nil,
                                     comment: StaticString? = nil
        ) -> String {
            string(forKey: key, defaultValue: defaultValue, table: table, bundle: bundle, comment: comment, options: [ ])
        }


        private borrowing func string(forKey key: KvLocalizedStringKey,
                                      defaultValue: String?,
                                      table: String?,
                                      bundle: Bundle?,
                                      comment: StaticString?,
                                      options: Options
        ) -> String {

            func Localized(_ key: String) -> String {
                let bundle = resolved(bundle ?? self.primaryBundle)

                return bundle.localizedString(forKey: key, value: defaultValue, table: table)
            }


            switch key.value {
            case .final(let key):
                return Localized(key)

            case .formatted(let format, let arguments):
                return .init(format: Localized(format), arguments: arguments.enumerated().map { (offset, value) in
                    switch value {
                    case .cVarArg(let value, format: _):
                        value
                    case .text(let text):
                        !options.contains(.textPlaceholders)
                        ? text.plainText(in: self)
                        : "%\(offset + 1)$T"
                    }
                })
            }
        }


        /// - Returns: Cached result of ``resolve(_:)`` for given *bundle*.
        private borrowing func resolved(_ bundle: Bundle) -> Bundle {
            guard bundle != self.primaryBundle else { return resolvedPrimaryBundle }

            return resolvedBundles[bundle]
        }

    }



    // MARK: .StringResource

    @usableFromInline
    struct StringResource : Equatable {

        var key: KvLocalizedStringKey
        var defaultValue: String?

        var table: String?
        var bundle: Bundle?


        @usableFromInline
        init(key: KvLocalizedStringKey, defaultValue: String? = nil, table: String? = nil, bundle: Bundle? = nil) {
            self.key = key
            self.defaultValue = defaultValue
            self.table = table
            self.bundle = bundle
        }

    }

}
